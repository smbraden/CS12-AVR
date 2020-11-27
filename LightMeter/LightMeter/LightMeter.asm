/*-------------------------------------------------------------------------------------//
    Project:			LightMeter
	Filename:           LightMeter.asm
    Author:				Sonja Braden
    Reference:			https://stackoverflow.com/questions/43193023/how-to-set-the-6th-bit-of-admux-on-atmega328p-in-avr-assembly-language
    Date:               11/25/2020
	Device:				ATmega328A
	Device details:		1MHz clock, 8-bit MCU
    Description:		Continuously measures light intensity, and represents the 
						intensity on a scale of 1 to 8, as displayed by a row of LED's
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
	jmp Reset						; the reset vector
;	jmp ADC_INT						; ADC Conversion Complete Handler
	

/******************** Reset vector */

Reset:								
    
	call initStack

	call initGPIO
	
	call initADC0
	
	/************** Begin Program Loop */

	ProgramLoop:
		
		ldi r16, 0
		call readADC
		lds r16, ADCH
		call LightDisplay

	jmp ProgramLoop




/********************* Subroutines */



/********************** GPIO Inits */
initGPIO:
	ser r16								; set all bits in register
	out DDRB, r16						; entire PORTB set to output
	
	cbi DDRC, PC0						; PC0 set to input
	sbi PORTC, PC0						; activaate pull-up resistors
ret





/**************** Initialize Stack */

initStack:
	ldi r16, HIGH(RAMEND)				; LDI = "Load Immediate Into"
	out SPH, r16						; SPH = "Stack Pointer High"
	ldi r16, LOW(RAMEND)		
	out SPL, r16						; SPL = "Stack Pointer Low"
ret




/********************** ADC Inits */

initADC0:
	ldi r16, (1 << REFS0)			; set REFS0 bit without disturbing other bits
	lds r15, ADMUX
	or r15, r16
	ldi r16, (1 << REFS1)			; clear REFS1 bit without disturbing other bits
	com r16
	and r15, r16

	sts ADMUX, r15					; voltage ref set to AVCC w/ external cap at AREF pin
	
	ldi r16, (1 << ADPS1)
	lds r15, ADCSRA
	or r15, r16
	sts ADCSRA, r15					; ADCSRA |= (1 << ADPS1) ADC prescalar division factor set to 4

	ldi r16, (1 << ADEN)
	sts ADCSRA, r16					; Set ADC enable bit
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

	loopUntilClear:
		lds r18, ADCSRA
		cp r18, r17
			breq exit
		jmp loopUntilClear

	exit:

	POP r18
	POP r17

ret



/******************** Dispaly Reading */

; Pre:		The 3-bit value is in r16
LightDisplay :

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
ret






/****** Interrupt service routines */
/*
ADC_INT:
	
	; Prologue
	PUSH r17							; save register on stack
	PUSH r18
	PUSH r26
	PUSH r27
	IN r17,SREG							; save flags

	lds r27, ADCH
	lds r26, ADCL
	
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
		sbi PORTB, r26					; operand 2 of sbi must be constant
		cpi r26, 0
		brge lightLoop
	
	mov r16, r26
	call LightDisplay
	

	; Epilogue
	OUT SREG,r17						; restore flags
	POP r27
	POP r26
	POP r18
	POP r17

RETI								; end of service routine

/***************** Interrupt Inits /

initInterrupts:

	ldi r16, (1 << ADIE)
	sts ADCSRA, r16						; Activate ADC Conversion Complete Interrupt
	
	SEI									; SREG = SREG | (1 << I)

ret

*/



/*

	Command : Cycle : Description

	ldi		: 1 : Load Immediate Into; Loads an 8-bit constant directly to regs.16 to 31.

	cbi		: 1 : Clear Bit In I/O Register — Clears a specified bit in an I/O register.

	sbi		: 1 : Set Bit in I/O Register — Sets a specified bit in an I/O Register.

	out		: 1 : Store Register to I/O Location — Stores data from register Rr in the 
					Register File to I/O Space(Ports, Timers, Configuration Registers, etc.).

	dec		: 1 : Decrement — Subtracts one from the contents of register Rd and 
					places the result in the destination register Rd.

	adiw	: 2 : Add Immediate to Word — Adds an immediate value (0–63) 
					to a register pair and places the result in the register pair.

	brne	: 2 : Branch if Not Equal — Conditional relative branch. 
					Tests the Zero Flag (Z) and branches relatively to PC if Z is cleared.

	rcall	: 1 : Relative Call to Subroutine — Relative call to an address within PC

	ret		: 1 : Return from Subroutine — Returns from the subroutine.

	rjmp	: 1 : Relative Jump — Relative jump to an address.

	sts		: 2 : Stores one byte from a Register to the data space.  For parts with SRAM, 
					the data space consists of the Register File, I/O memory, 
					and internal SRAM (and external SRAM if applicable).

*/