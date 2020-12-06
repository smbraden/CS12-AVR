
.ifndef DELAY_INC
.define DELAY_INC

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


.endif
