/*-------------------------------------------------------------------------------------//
    Project:			Hello_AtmelStudio
	Filename:           main.asm
    Author:				Sonja Braden
    Reference:			
    Date:               11/21/2020
	Device:				ATmega328A
	Device details:		1MHz clock, 8-bit MCU
    Description:		Toggle an I/O pin on port B of an ATmega328
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
	rjmp MAIN						; the reset vector
;	rjmp IntServRout1				; the interrupt service routine for the first interrupt
;	rjmp IntServRout2				; the interrupt service routine for the second interrupt

/****** Interrupt service routines */
/*
IntServRout1:

RETI								; end of service routine 1

IntServRout2:

RETI								; end of service routine 2

*/
/************** Begin Program Main */

MAIN:								
    
/**************** Initialize Stack */

ldi R16, HIGH(RAMEND)				; LDI = "Load Immediate Into"
out SPH, R16						; SPH = "Stack Pointer High"
ldi R16, LOW(RAMEND)		
out SPL, R16						; SPL = "Stack Pointer Low"

/***************** Initializations */

ldi r16, 0xFF						; load register 16 with 0xFF (all bits 1)
out DDRB, r16						; write the value in r16 (0xFF) to Data Direction Register B

SEI									; Set Interrupt Enable Bit

/**************** Begin blink loop */

ProgramLoop:

	sbi		PORTB, PB5				; "Set Bit In" pin high
	rcall	Delay			
	cbi		PORTB, PB5				; "Clear Bit In" pin low
	rcall	Delay			

rjmp ProgramLoop
	





/********************* Subroutines */

Delay :
	
	ldi r16, 5
	
	Outer_Loop:				; outer loop label
							; R26 - R31 are 16-bit
							; R27:R26 = X, R29:R28 = Y, R31:R30 = Z
		ldi r26, 0          ; clr r26; clear register 26
		ldi r27, 0          ; clr r27; clear register 27
							
		Inner_Loop:         ; the loop label
			adiw r26, 1		; Add Immediate to Word R27:R26 incremented
		brne Inner_Loop
		
		dec r16				; decrement r16

	brne Outer_Loop			; " Branch if Not Equal"

ret							; return from subroutine






/*

	Command : Cycle : Description

	ldi		: 1 : Load Immediate Into; Loads an 8-bit constant directly to regs.16 to 31.

	cbi		: 1 : Clear Bit In I/O Register  Clears a specified bit in an I/O register.

	sbi		: 1 : Set Bit in I/O Register  Sets a specified bit in an I/O Register.

	out		: 1 : Store Register to I/O Location  Stores data from register Rr in the 
					Register File to I/O Space(Ports, Timers, Configuration Registers, etc.).

	dec		: 1 : Decrement  Subtracts one from the contents of register Rd and 
					places the result in the destination register Rd.

	adiw	: 2 : Add Immediate to Word  Adds an immediate value (063) 
					to a register pair and places the result in the register pair.

	brne	: 2 : Branch if Not Equal  Conditional relative branch. 
					Tests the Zero Flag (Z) and branches relatively to PC if Z is cleared.

	rcall	: 1 : Relative Call to Subroutine  Relative call to an address within PC

	ret		: 1 : Return from Subroutine  Returns from the subroutine.

	rjmp	: 1 : Relative Jump  Relative jump to an address.

*/