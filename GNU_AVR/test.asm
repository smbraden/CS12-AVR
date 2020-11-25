;/*-------------------------------------------------------------------------------------//
;   Filename:			main.asm
;   Author:				Sonja Braden
;   Reference:			
;   Resources:			http://avra.sourceforge.net/README.html
;						https://github.com/Ro5bert/avra
;	Date:               11/21/2020
;	Device:				ATmega328A
;	Device details:		1MHz Clock, 8-bit MCU
;
;   Description:		Toggle an I/O pin on port B of an ATmega328
;//-------------------------------------------------------------------------------------*/

;.nolist							; Don't list the following in the list file
.include	"m328def.inc"
;.list							; Switch list on again

.device		ATmega328
.equ		F_CPU = 1000000 	; 1MHz Internal RC clock

;/************ SRAM defines */

.dseg
.org SRAM_START
; Format: Label: .BYTE N ; reserve N Bytes from Label:

;/************ Reset Vector */

.cseg						; lets the assembler switch output to the code section
.org		0x0000			; next instruction written to address 0x0000
							; first instruction of an executable always located at address 0x0000
;/******** Initialize Stack */

ldi r16, HIGH(RAMEND)		; LDI = "Load Immediate Into"
out SPH, r16				; SPH = "Stack Pointer High"
ldi r16, LOW(RAMEND)		
out SPL, r16				; SPL = "Stack Pointer Low"

;/********* Initialize GPIO */

ldi r16, 0xFF				; load register 16 with 0xFF (all bits 1)
out DDRB, r16				; write the value in r16 (0xFF) to Data Direction Register B

;/********* Function Defs */

Delay :
	
	ldi r16, 5
	
	Outer_Loop:				; outer loop label
							; R26 - R31 are 16-bit
							; R27:R26 = X, R29:R28 = Y, R31:R30 = Z
		ldi r26, 0          ; clr r26; clear register 26
		ldi r27, 0          ; clr r27; clear register 27
							
		Inner_Loop:         ; the loop label
			adiw r26, 1		; "Add Immediate to Word" R27:R26 incremented
		brne Inner_Loop
		
		dec r16				; decrement r16

	brne Outer_Loop			; " Branch if Not Equal"

ret							; return from subroutine

;/******** Main Event Loop */

MAIN:
	
	sbi		PORTB, PB5		; "Set Bit In" pin high
	rcall	Delay			
	cbi		PORTB, PB5		; "Clear Bit In" pin low
	rcall	Delay			
		
rjmp MAIN
	


