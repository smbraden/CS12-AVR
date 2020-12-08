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

.DEF		ADC_SAMPLE = r21		; don't use r21 anywhere else
.DEF		ADC_FLAG = r22			; don't use r21 anywhere else

/******************** SRAM defines */

.DSEG
.ORG SRAM_START

/********* Reset/Interrupt Vectors */

.CSEG								; lets the assembler switch output to the code section
.ORG		0x0000					; next instruction written to address 0x0000
									; first instruction of an executable always located at address 0x0000
	
	jmp Reset				; RESET
	reti					; INT0
	reti					; INT1
	reti					; PCINT0
	reti					; PCINT1
	reti					; PCINT2
	reti					; WDT
	reti					; TIMER2_COMPA
	reti					; TIMER2_COMPB
	reti					; TIMER2_OVF
	reti					; TIMER1_CAPT
	reti					; TIMER1_COMPA
	reti					; TIMER1_COMPB
	reti					; TIMER1_OVF
	jmp TIMER0_COMPA		; TIMER0_COMPA
	reti					; TIMER0_COMPB
	jmp TIMER0_OVF			; TIMER0_OVF
	reti					; SPI_STC
	reti					; USART_RX
	reti					; USART_UDRE
	reti					; USART_TX
	jmp ADC_CONV			; ADC
	reti					; EE_READY
	reti					; ANALOG_COMP
	reti					; TWI
	reti					; SPM_Ready

/******************** Reset Routine */

Reset:								
    
	/**************** Initialize Stack */

	ldi r16, HIGH(RAMEND)				; LDI = "Load Immediate Into"
	out SPH, r16						; SPH = "Stack Pointer High"
	ldi r16, LOW(RAMEND)		
	out SPL, r16						; SPL = "Stack Pointer Low"

	/**************** Initialize other */

	rcall initGPIO
	ldi r16, 0							; read channel 0
	rcall initSingleSampleADC		; prepare channel to sample continuously
	rcall testGPIO
	rcall initTimer

	ldi ADC_FLAG, FALSE
	ldi r16, DEFAULT_DELAY
	sei									; Enable global interrrupts

	/************** Begin Program Loop */
	
	ProgramLoop:
		
		call Delay_ms_byte					; delay for DEFAULT_DELAY milliseconds
	jmp ProgramLoop



/****** Interrupt service routines */

ADC_CONV:
	
	ldi ADC_FLAG,  TRUE
	lds ADC_SAMPLE, ADCH

reti




/***************** PWM Timer ISR's */


; Timer compare interrupt
TIMER0_COMPA: 

	; Prologue
	push r17							; save register on stack
	push r18
	in r17,SREG	
		
	clr r18
	out PORTB, r18						; PORTB all off 

	; Epilogue
	out SREG,r17						; restore flags
	pop r18
	pop r17

reti




; Timer counter overflow interrupt
TIMER0_OVF :

	; Prologue
	push r18							; save register on stack
	push r17
	in r17,SREG	

	ser r18
	out PORTB, r18						; PORTB all on 

	out OCR0A, ADC_SAMPLE				; set the new duty cycle

	; Epilogue
	out SREG,r17						; restore flags
	pop r17
	pop r18
	
reti




/********************* Subroutines */


/********************** GPIO Inits */

initGPIO:

	push r16
										; Output 
	ser r16								; set all bits in register
	out DDRB, r16						; entire PORTB set to output
	
										; Voltage sensor
	cbi DDRC, PC0						; PC0 set to input
	sbi PORTC, PC0						; activaate pull-up resistors

	pop r16
	
ret




/********************** ADC Inits */

initSingleSampleADC:

	push r15
	push r16

	ldi r16, (1 << REFS0)			; set REFS0 bit without disturbing other bits
	lds r15, ADMUX
	or r15, r16
	ldi r16, (1 << REFS1)			; clear REFS1 bit without disturbing other bits
	com r16
	and r15, r16
	sts ADMUX, r15					; Voltage Ref set to AVCC w/ external cap at AREF pin


	ldi r16, (1 << ADLAR)			
	lds r15, ADMUX
	or r15, r16
	sts ADMUX, r15					; left-adjusted conversion in the ADCH:ADCL
	

	ldi r16, (1 << ADPS2) | (1 << ADPS1)
	lds r15, ADCSRA
	or r15, r16
	sts ADCSRA, r15					; ADC prescalar division factor set to 64

	ldi r16, (1 << ADEN)
	sts ADCSRA, r16					; Set ADC enable bit

	pop r16
	pop r15

ret





; Pre:		The channel to be read is in r16 (a 3-bit value, 0-8)
initContiuousADC:

	push r17
	push r16
	
	lds r17, ADMUX
	and r17, r16					; all upper bits in ADMUX are set below
	sts ADMUX, r17					; read the argument channel

	ser r17
	cbr r17, (1 << ADTS2) | (1 << ADTS1) | (1 << ADTS0) 
	lds r16, ADCSRB
	and r17, r16
	sts ADCSRB, r17					; Auto-trigger source: free-running mode
	
	ldi r16, (1 << REFS1)
	lds r17, ADMUX
	or r17, r16
	cbr r17, REFS0
	sts ADMUX, r17					; Voltage Ref set to AVCC w/ external cap at AREF pin
	
	ldi r16, (1 << ADLAR)			
	lds r17, ADMUX
	or r17, r16
	sts ADMUX, r17					; left-adjusted conversion in the ADCH:ADCL

									; ADCSRA |= (1 << ADEN) ... ADC enable bit
									; ADCSRA |= (1 << ADATE) ... ADC Auto Trigger Enable
									; ADCSRA |= (1 << ADIE) ...   ADC Interrupt Enable

	ldi r16, (1 << ADEN) | (1 << ADATE) | ( 1 << ADIE)
	lds r17, ADCSRA
	or r17, r16						
	sts ADCSRA, r17					

	; ADCSRA |= (1 << ADPS2) ... prescalar division factor set to 128
	ldi r16, (1 << ADPS2) | (1 << ADPS1)| (1 << ADPS0)
	or r17, r16						
	sts ADCSRA, r17								

	pop r16
	pop r17

ret




/******************* Start an ADC conversion */

; Pre:		Single conversion mode is set.
;			The channel to be read is in r16 (a 3-bit value, 0-8)
; Post:		The conversion awaits in ADCH and ACDL
readADC:

	PUSH r18
	PUSH r17


	lds r17, ADMUX
	or r17, r16
	sts ADMUX, r17


	ldi r17, (1 << ADSC)				
	lds r18, ADCSRA
	or r17, r18
	sts ADCSRA, r17						; ADCSRA |= (1 << ADSC);

	lds r17, ADCSRA
	cbr r17, ADSC						; sample of ADSC bit cleared from ADCSRA

	loopUntilClear:						; ADCSRA out of range for sbic command
		lds r18, ADCSRA
		cp r18, r17
			breq exit
		jmp loopUntilClear

	exit:

	POP r18
	POP r17

ret




/********************** Init Timer */

initTimer:

	PUSH r17
	PUSH r16

	ldi r17, (1 << CS01) | (1 << CS00)
	in r16, TCCR0B
	or r17, r16
	out TCCR0B, r17						; clock division by prescalar of 64
										
	ldi r16, (1 << OCIE0A) | (1 << TOIE0)
	lds r17, TIMSK0						; TIMSK0 |= (1 << TOIE0) overflow interrupt enable
	or r17, r16							; TIMSK0 |= (1 << OCIE0A) TIM0 output compare interrupts
	sts TIMSK0, r17
	
	POP r16
	POP r17					
			
ret



/********************************* GPIO Test */

testGPIO :
	
	; PUSH r27
	; PUSH r26
	PUSH r19
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

	ldi r19, (1 << 0)
	ldi r17, 0
	
	LeftShiftLoop:
		out PORTB, r19
		lsl r19
		rcall Delay_ms_byte
		inc r17
		cpi r17, 7
	brlt LeftShiftLoop	
	
	RightShiftLoop:
		out PORTB, r19
		lsr r19
		rcall Delay_ms_byte
		inc r17
		cpi r17, 14
	brlt RightShiftLoop	

	inc r18
	cpi r18, 2
	brlt RepeatShifts	
	
	clr r17
	out PORTB, r17					 ; turn it off

	POP r16
	POP r17
	POP r18
	POP r19
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







