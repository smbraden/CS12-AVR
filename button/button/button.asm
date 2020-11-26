/*-------------------------------------------------------------------------------------//
    Project:			button
	Filename:           button.asm
    Author:				Sonja Braden
    Reference:			
    Date:               11/21/2020
	Device:				ATmega328A
	Device details:		1MHz clock, 8-bit MCU
    Description:		Toggle an I/O pin on port B when a button is pressed
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
	jmp EXT_INT0					; IRQ0 Handler
	;jmp EXT_INT1					; IRQ1 Handler




/******************** Reset vector */

Reset:								
    
	/**************** Initialize Stack */

	ldi r16, HIGH(RAMEND)				; LDI = "Load Immediate Into"
	out SPH, r16						; SPH = "Stack Pointer High"
	ldi r16, LOW(RAMEND)		
	out SPL, r16						; SPL = "Stack Pointer Low"

	/********************** GPIO Inits */

	ldi r16, (1 << PB5)					; bit mask PB5
	in r15, DDRB						; snapshot of register
	or r15, r16							; bit mask PB5 & former register state
	out DDRB, r15						; PB5 set to output
	
	ldi r16, (1 << PD2)					; bit mask PD2
	in r15, DDRD						; snapshot of register
	or r15, r16							; bit mask PD2 & former register state
	out DDRD, r15						; PD2 set to input

	in r15, PORTB						; snapshot of register
	or r15, r16							; bit mask PD2 & former register state
	out PORTB, r15						; PD2 pull-up resistors set
	

	/***************** Interrupt Inits */
	
	ldi r16, (1 << ISC00)				
	sts EICRA, r16						; trigger Inter for any logical change on INT0
	
	ldi r16, (1 << INT0)				
	out EIMSK, r16						;  external pin interrupt is enabled

	SEI									; Set Global Interrupt Enable Bit

	/************** Begin Program Loop */

	ProgramLoop:

	rjmp ProgramLoop








/****** Interrupt service routines */

EXT_INT0:
								
	push r19							; save register on stack
	push r18
	push r17							
	in r17, SREG						; save flags

	ldi r19, 5							; ~10ms debouncing delay (5 ticks)
	debounceLoop:
		dec r19
		cpi r19, 1
		brge debounceLoop
	
	in r19, PORTB						; snapshot of the current PORTB i/o state	
	ldi r18, (1 << PB5)					; PB5-toggling bit mask
	eor r19, r18						
	out PORTB, r19

	out SREG, r17						; restore flags
	pop r17
	pop r18
	pop r19
	
RETI								; end of service routine 1


/*

EXT_INT1:

PUSH r15							; save register on stack
IN r15,SREG							; save flags

;[... more instructions...] 

OUT SREG,r15						; restore flags
POP r15
RETI								; end of service routine 1

RETI								; end of service routine 2

*/

/********************* Subroutines */

Delay :
	
	ldi r16, 5
	
	Outer_Loop:				; outer loop label
							; R26 - R31 are 16-bit
							; R27:R26 = X, R29:R28 = Y, R31:R30 = Z
		ldi r26, 0          ; clr r26; clear register 26
		ldi r27, 0          ; clr r27; clear register 27
							
		Inner_Loop:         ; the loop label
			adiw r26, 1		; “Add Immediate to Word” R27:R26 incremented
		brne Inner_Loop
		
		dec r16				; decrement r16

	brne Outer_Loop			; " Branch if Not Equal"

ret							; return from subroutine






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