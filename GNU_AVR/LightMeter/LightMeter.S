;/*-------------------------------------------------------------------------------------//
;   Project:			LightMeter
;	Filename:			LightMeter.S
;   Author:				Sonja Braden
;   Reference:
;   Resources:			
;	Date:               11/21/2020
;	Device:				ATmega328A or ATmega168A
;	Device details:		1MHz Clock, 8-bit MCU
;
;   Description:		Continuously measures light intensity, and represents the 
;						intensity on a scale of 1 to 8, as displayed by a row of LED's
;
;	Circuit:			ADC pin (PC0) tied to the node of a voltage divider formed by
;						a ~35kOhm photoresistor and a 10kOhm constant resistance.
;//-------------------------------------------------------------------------------------*/

.NOLIST								; Don't list the following in the list file
.INCLUDE	"../includes/m328def.inc"
;.INCLUDE	"../includes/m168def.inc"
.LIST								; Switch list on again

.EQU		F_CPU = 1000000			; 1MHz Internal RC clock

;/******************** SRAM defines */

.DSEG
.ORG SRAM_START
; Format: Label: .BYTE N ; reserve N Bytes from Label:

;/********* Reset/Interrupt Vectors */

.CSEG								; lets the assembler switch output to the code section
.ORG		0x0000					; next instruction written to address 0x0000
									; first instruction of an executable always located at address 0x0000

;/******************** Reset vector */

Reset:								
    
	;/**************** Initialize Stack */

	ldi r16, HIGH(RAMEND)				; LDI = "Load Immediate Into"
	out SPH, r16						; SPH = "Stack Pointer High"
	ldi r16, LOW(RAMEND)		
	out SPL, r16						; SPL = "Stack Pointer Low"

	;/**************** Initialize other */

	call initGPIO
		
	call initADC0
	
	call testGPIO

	;/************** Begin Program Loop */

	ProgramLoop:
		
		ldi r16, 0
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




;/********************* Subroutines */


;/********************** GPIO Inits */

initGPIO:
	push r16

	ser r16								; set all bits in register
	out DDRB, r16						; entire PORTB set to output
	
	cbi DDRC, PC0						; PC0 set to input
	sbi PORTC, PC0						; activaate pull-up resistors

	pop r16
ret




;/********************** ADC Inits */

initADC0:
	push r16
	push r17

	ldi r16, (1 << REFS0)			; set REFS0 bit without disturbing other bits
	lds r17, ADMUX
	or r17, r16
	ldi r16, (1 << REFS1)			; clear REFS1 bit without disturbing other bits
	com r16
	and r17, r16
	sts ADMUX, r17					; Voltage Ref set to AVCC w/ external cap at AREF pin
	
	ldi r16, (1 << ADLAR)			
	lds r17, ADMUX
	or r17, r16
	sts ADMUX, r17					; left-adjusted conversion in the ADCH:ADCL

	ldi r16, (1 << ADPS1)
	lds r17, ADCSRA
	or r17, r16
	sts ADCSRA, r17					; ADCSRA |= (1 << ADPS1) ADC prescalar division factor set to 4

	ldi r16, (1 << ADEN)
	sts ADCSRA, r16					; Set ADC enable bit

	pop r17
	pop r16
ret

;/********************************* GPIO Test */

testGPIO:
	
	PUSH r18
	PUSH r17
	PUSH r16
	
	; Flash PortB a few times
;	ldi XH, high(500)
;	ldi XL, low(500)				; could also just clr this reg

;	clr r16
;	BlinkLoop:
;		ser r17
;		out PORTB, r17
;		rcall Delay_ms
;		clr r17
;		out PORTB, r17
;		rcall Delay_ms

;		inc r16
;		cpi r16, 0x3
;		brlt BlinkLoop

	ldi r18, 0
	RepeatShifts:						; Traverse the port a few times

	ldi r16, (1 << 0)
	ldi r17, 0
	
	ldi XH, high(100)
	ldi XL, low(100)				; could also just clr this reg

	LeftShiftLoop:
		out PORTB, r16
		lsl r16
		rcall Delay_ms
		inc r17
		cpi r17, 7
	brlt LeftShiftLoop	
	
	RightShiftLoop:
		out PORTB, r16
		lsr r16
		rcall Delay_ms
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




;/************* Parameterized Delay */


; Pre:		r27:r26 contains the number of milliseconds
; Post:		ROUGH delay in milliseconds
Delay_ms:

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
		
		sbiw r26, 1		; �Add Immediate to Word� R27:R26 incremented
		brne milliLoop
	
	pop r27
	pop r26
	pop r17
	pop r16

ret


;/******************* Start an ADC conversion */

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
		jmp loopUntilClear

	exit:

	POP r18
	POP r17

ret



;/******************** Dispaly Reading */

; Pre:		The 3-bit value is in r16
LightDisplay:

	PUSH r17

	clr r17
	out PORTB, r17

	cpi r16, 1
	brge pin1
	jmp next1
	pin1:
		sbi PORTB, 0
	
	next1:
	cpi r16, 2
	brge pin2
	jmp next2
	pin2:
		sbi PORTB, 1

	next2:
	cpi r16, 3
	brge pin3
	jmp next3
	pin3:
		sbi PORTB, 2

	next3:
	cpi r16, 4
	brge pin4
	jmp next4
	pin4:
		sbi PORTB, 3

	next4:
	cpi r16, 5
	brge pin5
	jmp next5
	pin5:
		sbi PORTB, 4

	next5:
	cpi r16, 6
	brge pin6
	jmp next6
	pin6:
		sbi PORTB, 5

	next6:
	cpi r16, 7
	brge pin7
	jmp next7
	pin7:
		sbi PORTB, 6

	next7:
	cpi r16, 8
	brge pin8
	jmp next8
	pin8:
		sbi PORTB, 7

	next8:

	POP r17

ret

