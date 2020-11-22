/*/-------------------------------------------------------------------------------------//
    Filename:           main.asm
    Author:				Sonja Braden
    Reference:	
    Date:               11/21/2020
    Description:
//-------------------------------------------------------------------------------------/*/

.NOLIST					; Don't list the following in the list file
.INCLUDE "m328def.inc"	; "M328DEF.INC"
.LIST					; Switch list on again

.DEVICE ”ATMEGA328”		; The target device type (actually using ATmega328A)

.ORG 0

LDI R16, HIGH(RAMEND)
OUT SPH, R16
LDI R16, LOW(RAMEND)
OUT SPL, R16

; Replace with your application code
MAIN:
    
	LDI R16, 0x00
	OUT PORTB, R16
	CALL Delay
	LDI R16, 0xFF
	OUT PORTB, R16
	CALL Delay
	RJMP MAIN

Delay :
	
	LDI R16, 0xFF


