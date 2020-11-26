;//-------------------------------------------------------------------------------------//
;   Project:			LightMeter
;	Filename:           LightMeter.asm
;   Author:				Sonja Braden
;   Reference:			
;   Date:               11/25/2020
;	Device:				ATmega328A
;	Device details:		1MHz clock, 8-bit MCU
;   Description:		Continuously measures light intensity, and represents the 
;						intensity on a scale of 1 to 8, as displayed by a row of LEDs
;//-------------------------------------------------------------------------------------//

.NOLIST								; Don't list the following in the list file
.INCLUDE	"../m328def.inc"		; 
.LIST								; Switch list on again

.EQU		F_CPU = 1000000			; 1MHz Internal RC clock
.DEVICE		ATmega328				; The target device type (actually using ATmega328A)

;/******************** SRAM defines */

.DSEG
.ORG SRAM_START
; Format: Label: .BYTE N ; reserve N Bytes from Label:

;/********* Reset/Interrupt Vectors */

.CSEG								; lets the assembler switch output to the code section
.ORG		0x0000					; next instruction written to address 0x0000
									; first instruction of an executable always located at address 0x0000
	jmp Reset						; the reset vector
	jmp ADC_INT						; ADC Conversion Complete Handler
	

;/******************** Reset vector */

Reset:								
    
	;/**************** Initialize Stack */

	ldi r16, HIGH(RAMEND)				; LDI = "Load Immediate Into"
	out SPH, r16						; SPH = "Stack Pointer High"
	ldi r16, LOW(RAMEND)		
	out SPL, r16						; SPL = "Stack Pointer Low"

	;/********************** GPIO Inits */

	ser r16								; set all bits in register
	out DDRB, r16						; entire PORTB set to output
	
	cbi DDRC, PC0						; PC0 set to input
	sbi PORTC, PC0						; activaate pull-up resistors
		
	;/***************** Interrupt Inits */

	sbi ADCSRA, ADIE					; Activate ADC Conversion Complete Interrupt
	
	SEI									; SREG = SREG | (1 << I)

	;/**********************% ADC Inits */
	
	; Set voltage reference to AVCC with external capacitor at AREF pin
	sbi ADMUX, REFS0
	cbi ADMUX, REFS1
	
	sbi ADCSRA, ADEN					; Set ADC enable bit


	;/************** Begin Program Loop */

	ProgramLoop:

	rjmp ProgramLoop








;/****** Interrupt service routines */


ADC_INT:
	
	; Prologue
	PUSH r17							; save register on stack
	PUSH r18
	PUSH r19
	PUSH r26
	PUSH r27
	IN r17,SREG							; save flags

	in r26, ADCL
	in r27, ADCH

	; 2^10		= 1024
	; 1024/128	= 8
	; 2^7		= 128
	
	clr r18								; iterator
	shiftLoop:
		lsr r27							; shift r27:r26 left by 7
		inc r18
		cpi r18, 7
		brlt shiftLoop

	clr r18
	out PORTB, r18								
	lightLoop:
		sbi PORTB, r26
		cpi r26, 0
		brge lightLoop
	
	; Epilogue
	OUT SREG,r17						; restore flags
	POP r27
	POP r26
	POP r19
	POP r18
	POP r17

RETI								; end of service routine




