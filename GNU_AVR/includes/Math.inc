
.ifndef MATH_INC
.define MATH_INC

;/********************** Square Byte */

; Pre:			r26 holds the byte value to be squared
; Post:		R27:R26 holds the word result
Square_byte:

	push r17
	push r0
	push r1

	mov r17, r26
	mul r26, r17
	mov r27, r1
	mov r26, r0

	pop r1
	pop r0
	pop r17

ret


;/******************** Square a Nibble */

; Pre:			higher nibble (bits 7:4) of r16 contains the value to be squared
; Post:		r16 holds the square of the nibble (a byte)

Square_nibble:

	push r17
	push r0
	push r1
	
	lsr r16					
	lsr r16
	lsr r16
	lsr r16

	mov r17, r16
	mul r16, r17
	mov r16, r0				; r1:r0 holds the result of multiplications

	pop r1
	pop r0
	pop r17

ret

.endif
