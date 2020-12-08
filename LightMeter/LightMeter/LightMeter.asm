/*-------------------------------------------------------------------------------------//
    Project:			LightMeter
	Filename:           LightMeter.asm
    Author:				Sonja Braden
    Reference:			
    Date:               11/25/2020
	Device:				ATmega328A
	Device details:		1MHz clock, 8-bit MCU
    Description:		Continuously measures light intensity, and represents the 
						intensity on a scale of 1 to 8, as displayed by a row of LED's

	Circuit:			ADC pin (PC0) tied to the node of a voltage divider formed by
						a ~35kOhm photoresistor and a 10kOhm constant resistance.						
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

/******************** Reset vector */

Reset:								
    
	/**************** Initialize Stack */

	ldi r16, HIGH(RAMEND)				; LDI = "Load Immediate Into"
	out SPH, r16						; SPH = "Stack Pointer High"
	ldi r16, LOW(RAMEND)		
	out SPL, r16						; SPL = "Stack Pointer Low"

	/**************** Initialize other */

	rcall initGPIO
		
	rcall initADC
	
	rcall testGPIO

	/************** Begin Program Loop */

	ProgramLoop:
		
		ldi r16, 0							; read channel 0
		call readADC
		lds r16, ADCH
		
		clr r18
		shiftLoop:
			lsr r16							; equivalent to left shifting r27:r26 by 7
			inc r18
			cpi r18, 5
		brlt shiftLoop

		rcall LightDisplay					; r16 now holds the 3-bit reading

	jmp ProgramLoop




/********************* Subroutines */


/********************** GPIO Inits */

initGPIO:
	ser r16								; set all bits in register
	out DDRB, r16						; entire PORTB set to output
	
	cbi DDRC, PC0						; PC0 set to input
	sbi PORTC, PC0						; activate pull-up resistors
ret




/********************** ADC Inits */

initADC:
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

	loopUntilClear:						; ADCSRA out of range for sbic command
		lds r18, ADCSRA
		cp r18, r17
			breq exit
		rjmp loopUntilClear

	exit:

	POP r18
	POP r17

ret



/******************** Dispaly Reading */

; Pre:		The 3-bit value is in r16
LightDisplay :

	PUSH r15

	clr r15
	out PORTB, r15

	cpi r16, 1
	brge pin1
	rjmp next1
	pin1:
		sbi PORTB, 0
	
	next1:
	cpi r16, 2
	brge pin2
	rjmp next2
	pin2:
		sbi PORTB, 1

	next2:
	cpi r16, 3
	brge pin3
	rjmp next3
	pin3:
		sbi PORTB, 2

	next3:
	cpi r16, 4
	brge pin4
	rjmp next4
	pin4:
		sbi PORTB, 3

	next4:
	cpi r16, 5
	brge pin5
	rjmp next5
	pin5:
		sbi PORTB, 4

	next5:
	cpi r16, 6
	brge pin6
	rjmp next6
	pin6:
		sbi PORTB, 5

	next6:
	cpi r16, 7
	brge pin7
	rjmp next7
	pin7:
		sbi PORTB, 6

	next7:
	cpi r16, 8
	brge pin8
	rjmp next8
	pin8:
		sbi PORTB, 7

	next8:

	POP r15

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




