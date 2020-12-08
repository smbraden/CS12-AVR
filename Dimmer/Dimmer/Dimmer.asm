/*-------------------------------------------------------------------------------------//
    Project:			Dimmer
	Filename:           Dimmer.asm
    Author:				Sonja Braden
    Reference:			https://github.com/hexagon5un/AVR-Programming
    Date:               12/06/2020
	Device:				ATmega328A
	Device details:		1MHz clock, 8-bit MCU
    Description:		Uses PWM to dim/brighten an LED display depending on the 
						ACD voltage reading. ISR's are used to hack pwm on all PORTB pins
//-------------------------------------------------------------------------------------*/

.NOLIST								; Don't list the following in the list file
.INCLUDE	"m328def.inc"			
.LIST								; Switch list on again

.EQU		F_CPU = 1000000			; 1MHz Internal RC clock
.EQU		TRUE = 0x01
.EQU		FALSE = 0x00
.EQU		DEFAULT_DELAY = 3

.DEF		ADC_SAMPLE	= r19
.DEF		F_MASK		= r20
.DEF		NULL_MASK	= r21

/******************** SRAM defines */

.DSEG
.ORG SRAM_START

/********* Reset/Interrupt Vectors */

.CSEG								; lets the assembler switch output to the code section
.ORG		0x0000					; next instruction written to address 0x0000
									; first instruction of an executable always located at address 0x0000
	
	jmp Reset				; RESET
	jmp TIMER0_COMPA		; TIMER0_COMPA
	jmp TIMER0_OVF			; TIMER0_OVF
	

/******************** Reset Routine */

Reset:								
    
	/**************** Initialize Stack */

	ldi r16, HIGH(RAMEND)				; LDI = "Load Immediate Into"
	out SPH, r16						; SPH = "Stack Pointer High"
	ldi r16, LOW(RAMEND)		
	out SPL, r16						; SPL = "Stack Pointer Low"

	/************ Initialize Named reg */
	
	ser F_MASK							; 0xFF
	clr NULL_MASK						; 0x00

	/************* Initialize hardware */

;	ldi r16, 0							; read channel 0
;	rcall initContiuousADC				; prepare channel to sample continuously
	rcall initSingleSampleADC
	rcall initGPIO
	rcall testGPIO
	rcall initTimer

	sei									; Enable global interrrupts

	/************** Begin Program Loop */
	
	ProgramLoop:
	
	jmp ProgramLoop



/****** Interrupt service routines */


/***************** PWM Timer ISR's */


; Timer compare interrupt
TIMER0_COMPA: 

	; Prologue
	push r17							; save register on stack
	in r17,SREG	
	
	out PORTB, NULL_MASK				; PORTB all off 

	; Epilogue
	out SREG,r17						; restore flags
	pop r17

reti




; Timer counter overflow interrupt
TIMER0_OVF :

	; Prologue
	push r17
	in r17,SREG	
	
	;******* Single conversion mode
	
	ldi r16, 0	
	call readADC
	lds ADC_SAMPLE, ADCH
	out OCR0A, ADC_SAMPLE				; set the new duty cycle
	out PORTB, F_MASK					; PORTB all on 
	
	;******* Continuous mode
	/*
	out PORTB, F_MASK					; PORTB all on
	lds ADC_SAMPLE, ADCH				; set the new duty cycle
	out OCR0A, ADC_SAMPLE				; set the new duty cycle
	*/

	; Epilogue
	out SREG,r17						; restore flags
	pop r17
		
reti




/********************* Subroutines */


/********************** GPIO Inits */

initGPIO:

										; Output 
	out DDRB, F_MASK					; entire PORTB set to output
	
										; Voltage sensor
	cbi DDRC, PC0						; PC0 set to input
	sbi PORTC, PC0						; activaate pull-up resistors

ret




/********************** ADC Inits */


; Pre:		The channel to be read is in r16 (a 3-bit value, 0-8)
initContiuousADC:

	push r17
	
	lds r17, ADMUX
	and r17, r16					; read the argument channel
	sbr r17, (1 << REFS1)			
	cbr r17, (1 << REFS0)			; Voltage Ref set to AVCC w/ external cap at AREF pin
	sbr r17, (1 << ADLAR)			; left-adjusted conversion in the ADCH:ADCL
	sts ADMUX, r17					

	lds r17, ADCSRB
	cbr r17, (1 << ADTS2) | (1 << ADTS1) | (1 << ADTS0) 
	sts ADCSRB, r17					; Auto-trigger source: free-running mode

									; ADCSRA |= (1 << ADEN) ... ADC enable bit
									; ADCSRA |= (1 << ADATE) ... ADC Auto Trigger Enable
									; ADCSRA |= (1 << ADIE) ...   ADC Interrupt Enable
	lds r17, ADCSRA
	sbr r17, (1 << ADEN) | (1 << ADATE) | ( 1 << ADIE)
	
	sbr r17, (1 << ADPS2) | (1 << ADPS1)	; prescalar division factor 64
	cbr r17, (1 << ADPS0)
	
	sts ADCSRA, r17							
	/*
	ADPS2	ADPS1	ADPS0	Division Factor
	0		0		0		2
	0		0		1		2
	0		1		0		4
	0		1		1		8
	1		0		0		16
	1		0		1		32
	1		1		0		64
	1		1		1		128
	*/

	pop r17

ret





initSingleSampleADC:

	push r17

	lds r17, ADMUX
	sbr r17, (1 << REFS0)
	cbr r17, (1 << REFS1)			; Voltage Ref set to AVCC w/ external cap at AREF pin
	sbr r17, (1 << ADLAR)			; left-adjusted conversion in the ADCH:ADCL
	sts ADMUX, r17
		
	
	lds r17, ADCSRA

	sbr r17, (1 << ADPS1)				; ADC prescalar division factor set to 4
	cbr r17, (1 << ADPS2) | (1 << ADPS0)
	sbr r17, (1 << ADEN)				; Set ADC enable bit
	sts ADCSRA, r17					
	/*
	ADPS2	ADPS1	ADPS0	Division Factor
	0		0		0		2
	0		0		1		2
	0		1		0		4
	0		1		1		8
	1		0		0		16
	1		0		1		32
	1		1		0		64
	1		1		1		128
	*/

	pop r17

ret




/******************* Start an ADC conversion */

; Pre:		Single conversion mode is set.
;			The channel to be read is in r16 (a 3-bit value, 0-8)
; Post:		The conversion awaits in ADCH and ACDL
readADC:

	PUSH r17
	PUSH r18

	lds r17, ADMUX
	or r17, r16
	sts ADMUX, r17

	lds r17, ADCSRA
	sbr r17, (1 << ADSC)
	sts ADCSRA, r17						; ADCSRA |= (1 << ADSC);

	cbr r17, (1 << ADSC)				; sample of ADSC bit cleared from ADCSRA
	
	loopUntilClear:						; ADCSRA out of range for sbic command
		lds r18, ADCSRA
		cp r18, r17
			breq exit
		jmp loopUntilClear				; (*) Refactoring note
	
	exit:

	POP r18
	POP r17

ret

/*
	
(*)	loopUntilClear:
		cpi r17, ADCSRA
			breq exit
		jmp loopUntilClear
*/



/********************** Init Timer */

initTimer:

	PUSH r17
	
	in r17, TCCR0B
	sbr r17, (1 << CS01) | (1 << CS00)
	cbr r17, (1 << CS02)
	out TCCR0B, r17							; clock division prescalar set to 64
							
	/*
	CS02	CS01	CS00	Description
	0		0		0		No clock source (Timer/Counter stopped)
	0		0		1		clkI/O/(No prescaling)
	0		1		0		clkI/O/8 (From prescaler)
	0		1		1		clkI/O/64 (From prescaler)
	1		0		0		clkI/O/256 (From prescaler)
	1		0		1		clkI/O/1024 (From prescaler)
	1		1		0		External clock source on T0 pin. Clock on falling edge.
	1		1		1		External clock source on T0 pin. Clock on rising edge
	*/						
						
	lds r17, TIMSK0							; TIMSK0 |= (1 << TOIE0) overflow interrupt enable
	sbr r17, (1 << OCIE0A) | (1 << TOIE0)	; interrupt for compare register A
	cbr r17, (1 << OCIE0B)					; no interrupt for compare register B
	sts TIMSK0, r17
	
	POP r17					
			
ret














/********************************* GPIO Test */

testGPIO :
	
	; PUSH r27
	; PUSH r26
	PUSH r18
	PUSH r17
	PUSH r16
	
	; Flash PortB a few times
	/*
	clr r16
	BlinkLoop:
		
		ldi XL, low(500)
		ldi XH, high(500)

		ser r17
		out PORTB, r17
		rcall Delay_ms_word
		clr r17
		out PORTB, r17
		rcall Delay_ms_word

		inc r16
		cpi r16, 0x2
		brlt BlinkLoop
	*/

	ldi r16, 100
	ldi r18, 0
	RepeatShifts:						; Traverse the port a few times

	ldi r17, (1 << 0)
	
	LeftShiftLoop:
		out PORTB, r17
		rcall Delay_ms_byte
		lsl r17
		cpi r17, (1 << 7)
	brne LeftShiftLoop	
	
	RightShiftLoop:
		out PORTB, r17
		rcall Delay_ms_byte
		lsr r17
		cpi r17, (1 << 0)
	brne RightShiftLoop	

	inc r18
	cpi r18, 2
	brlt RepeatShifts	
	
	clr r17
	out PORTB, r17					 ; turn it off

	POP r16
	POP r17
	POP r18
	; POP r26
	; POP r27

ret




;/************* Parameterized Delays */

; Pre:		r27:r26 contains the number of milliseconds
Delay_ms_word:

	push r16
	push r17
	push r26
	push r27
	
	ldi r16, 100
	ldi r17, 10
	milliLoop:
	
		microLoop1:
		subi r16, 1
		brne microLoop1

		microLoop2:
		subi r17, 1
		brne microLoop2
		
		sbiw r26, 1
		brne milliLoop
	
	pop r27
	pop r26
	pop r17
	pop r16

ret




; Pre:		r16 contains the number of milliseconds
Delay_ms_byte:

	push r16
	push r17
	push r18	

	ldi r18, 100
	ldi r17, 10
	milliLoop_b:
	
		microLoop1_b:
		subi r18, 1
		brne microLoop1_b

		microLoop2_b:
		subi r17, 1
		brne microLoop2_b
		
		subi r16, 1
		brne milliLoop_b
	
	pop r18
	pop r17
	pop r16

ret




; Pre:		r27:r26 contains the number of microseconds
Delay_us_word:


	push r26
	push r27
	
	microLoop:
	sbiw r26, 1
	brne microLoop
	
	pop r27
	pop r26

ret




; Pre:		r16 has the number of ticks to count
Delay_us_byte:

	push r16

	delayLoop:
		
		subi r16, 1
		brne delayLoop
	
	pop r16
ret







