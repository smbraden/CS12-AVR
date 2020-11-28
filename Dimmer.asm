/*-------------------------------------------------------------------------------------//
    Project:			Dimmer
	Filename:           Dimmer.asm
    Author:				Sonja Braden
    Reference:			https://github.com/hexagon5un/AVR-Programming
    Date:               11/27/2020
	Device:				ATmega328A
	Device details:		1MHz clock, 8-bit MCU
    Description:		Continuously measures light intensity, and uses PWM to dim/brighten
						an LED display in response to less/more light intensity on a sensor.
//-------------------------------------------------------------------------------------*/

.NOLIST								; Don't list the following in the list file
.INCLUDE	"m328def.inc"			; 
.LIST								; Switch list on again

.EQU		F_CPU = 1000000			; 1MHz Internal RC clock
.DEVICE		ATmega328				; The target device type (actually using ATmega328A)

/******************** SRAM defines */

.DSEG
.ORG SRAM_START
; Format: Label: .BYTE N ; reserve N Bytes from Label:

/********* Reset/Interrupt Vectors */

.CSEG								; lets the assembler switch output to the code section
.ORG		0x0000					; next instruction written to address 0x0000
									; first instruction of an executable always located at address 0x0000
	rjmp Reset						; the reset vector
	rjmp TIMER0_COMPA				; TIMER0_COMPA interrupt
	rjmp TIMER0_OVF					; timer overflow inerrupt
/******************** Reset vector */

Reset:								
    
	/**************** Initialize Stack */

	ldi r16, HIGH(RAMEND)				; LDI = "Load Immediate Into"
	out SPH, r16						; SPH = "Stack Pointer High"
	ldi r16, LOW(RAMEND)		
	out SPL, r16						; SPL = "Stack Pointer Low"

	/**************** Initialize other */

	rcall initGPIO
		
	rcall initADC0
	
	rcall testGPIO

	rcall initTimer

	/************** Begin Program Loop */

	ProgramLoop:
		
		ldi r16, 0						; read channel 0
		rcall readADC
		
	rjmp ProgramLoop




/********************* Subroutines */

/********************** Init Timer */

initTimer :

	ldi r16, (1 << CS01)
	ldi r17, (1 << CS00)
	or r17, r16
	in r16, TCCR0B
	or r17, r16
	out TCCR0B, r17						; TCCR0B |= (1 << CS01) | (1 << CS00) for /64 prescalar 
										; OR TRY: TCCR0B |= (1 << CS01) for /8 prescalar 
	ldi r16, (1 << OCIE0A)
	lds r17, TIMSK0
	or r17, r16
	sts TIMSK0, r17						; TIMSK0 |= (1 << OCIE0A) TIM0 compare interrupts

	ldi r16, (1 << TOIE0)
	lds r17, TIMSK0
	or r17, r16
	sts TIMSK0, r17						; TIMSK0 |= (1 << TOIE0); overflow interrupt enable			
	
	SEI									; Enable global interrrupts
									
ret


/********************** GPIO Inits */

initGPIO:

	push r16

	ser r16								; set all bits in register
	out DDRB, r16						; entire PORTB set to output
	
	cbi DDRC, PC0						; PC0 set to input
	sbi PORTC, PC0						; activaate pull-up resistors

	pop r16

ret




/********************** ADC Inits */

initADC0:

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

	ldi r16, (1 << ADPS1)
	lds r15, ADCSRA
	or r15, r16
	sts ADCSRA, r15					; ADCSRA |= (1 << ADPS1) ADC prescalar division factor set to 4

	ldi r16, (1 << ADEN)
	sts ADCSRA, r16					; Set ADC enable bit

	pop r16
	pop r15

ret


/********************************* GPIO Test */


testGPIO :
	
	PUSH r18
	PUSH r17
	PUSH r16
	
	; Flash PortB a few times
	clr r16
	BlinkLoop:
		ser r17
		out PORTB, r17
		rcall DelayL
		clr r17
		out PORTB, r17
		rcall DelayL

		inc r16
		cpi r16, 0x3
		brlt BlinkLoop
	
	ldi r18, 0
	RepeatShifts:						; Traverse the port a few times

	ldi r16, (1 << 0)
	ldi r17, 0
	
	LeftShiftLoop:
		out PORTB, r16
		lsl r16
		rcall DelayF
		inc r17
		cpi r17, 7
	brlt LeftShiftLoop	
	
	RightShiftLoop:
		out PORTB, r16
		lsr r16
		rcall DelayF
		inc r17
		cpi r17, 14
	brlt RightShiftLoop	

	inc r18
	cpi r18, 2
	brlt RepeatShifts	

	clr r17
	out PORTB, r17

	POP r16
	POP r17
	POP r18

ret





DelayL :
	
	push r16
	push r26
	push r27

	ldi r16, 5
	
	Outer_Loop:				
							; R27:R26 = X, R29:R28 = Y, R31:R30 = Z
		ldi r26, 0          ; clr r26; clear register 26
		ldi r27, 0          ; clr r27; clear register 27
							
		Inner_Loop:         
			adiw r26, 1		; “Add Immediate to Word” R27:R26 incremented
		brne Inner_Loop
		
		dec r16				; decrement r16

	brne Outer_Loop			; " Branch if Not Equal"

	pop r27
	pop r26
	pop r16

ret							; return from subroutine




DelayF :
	
	push r26
	push r27
						; R27:R26 = X, R29:R28 = Y, R31:R30 = Z
	ldi r26, 0          ; clr r26; clear register 26
	ldi r27, 0          ; clr r27; clear register 27
							
	Counter_Loop:       
		adiw r26, 1		; “Add Immediate to Word” R27:R26 incremented
	brne Counter_Loop

	pop r27
	pop r26
			
ret							; return from subroutine


/******************* Start an ADC conversion */

; Pre:		The channel to be read is in r16 (a 3-bit value, 0-8)
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

	loopUntilClear:
		lds r18, ADCSRA
		cp r18, r17
			breq exit
		rjmp loopUntilClear

	exit:

	POP r18
	POP r17

ret





/****** Interrupt service routines */

TIMER0_COMPA: 

	; Prologue
	push r17							; save register on stack
	push r18
	push r19
	in r17,SREG	

	in r18, PORTB
	ser r19
	eor r18, r19
	out PORTB, r18						; toogle all output on PORTB

	; Epilogue
	out SREG,r17						; restore flags
	pop r19
	pop r18
	pop r17

reti


TIMER0_OVF :

	; Prologue
	push r17							; save register on stack
	push r18
	in r17,SREG	

	lds r18, ADCH
	com r18							; set the timer to the 1's complement of the 8-bit ADC reading
	out OCR0A, r18

	; Epilogue
	out SREG,r17						; restore flags
	pop r18
	pop r17

reti