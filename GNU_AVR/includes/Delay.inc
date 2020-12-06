
;/************* Parameterized Delays */


; Pre:		r27:r26 contains the number of milliseconds
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
		
		sbiw r26, 1
		brne milliLoop
	
	pop r27
	pop r26
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




;/********************** Square Byte */

; Pre:			r26 holds the byte value to be squared
; Post:			R27:R26 holds the word result
Square_byte :

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
; Post:			r16 holds the square of the nibble (a byte)

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

