;/*-------------------------------------------------------------------------------------//
;	Project:			template
;	Filename:           template.S
;	Author:				author
;	Date:               system_date_time
;	Device:				ATmega328A
;	Device details:		1MHz internal clock, 8-bit CPU, Vcc = 5 volts
;
;	Description:
;	Circuit:
;//-------------------------------------------------------------------------------------*/

.NOLIST								; Don't list the following in the list file
.INCLUDE	"../includes/m328def.inc"
.LIST								; Switch list on again

.EQU		F_CPU = 1000000			; 1MHz Internal RC clock
.EQU		LOWER_BOUND = 5			;
.EQU		DEFAULT_DELAY = 400		; (*) 100 - 400 good range
.EQU		ON = 0x01
.EQU		OFF = 0x00

.DEF		SLEEP_IDLE = r20		; don't use r20 anywhere else

;/******************** SRAM defines */

.DSEG
.ORG SRAM_START
; Format: Label: .BYTE N ; reserve N Bytes from Label:

;/********* Reset/Interrupt Vectors */

.CSEG								; lets the assembler switch output to the code section
.ORG		0x0000					; next instruction written to address 0x0000
									; first instruction of an executable always located at address 0x0000
	rjmp Reset				; RESET
	reti					; INT0
	reti					; INT1
	reti					; PCINT0
	reti					; PCINT1
	reti					; PCINT2
	reti					; WDT
	reti					; TIMER2_COMPA
	reti					; TIMER2_COMPB
	reti					; TIMER2_OVF
	reti					; TIMER1_CAPT
	reti					; TIMER1_COMPA
	reti					; TIMER1_COMPB
	reti					; TIMER1_OVF
	reti					; TIMER0_COMPA
	reti					; TIMER0_COMPB
	reti					; TIMER0_OVF
	reti					; SPI_STC
	reti					; USART_RX
	reti					; USART_UDRE
	reti					; USART_TX
	reti					; ADC
	reti					; EE_READY
	reti					; ANALOG_COMP
	reti					; TWI
	reti					; SPM_Ready


;/******************** Reset Routine */

Reset:

	;/**************** Initialize Stack */

	ldi r16, HIGH(RAMEND)
	out SPH, r16						; SPH = Stack Pointer High
	ldi r16, LOW(RAMEND)
	out SPL, r16						; SPL = Stack Pointer Low

	;/**************** Initialize other */

	call initGPIO
	call testGPIO

	;/************** Begin Program Loop */

	ldi r18, (1 << PB5)
	ldi XL, low(500)
	ldi XH, high(500)

	ProgramLoop:

		in r17, PORTB
		eor r17, r18
		out PORTB, r17
		rcall Delay_ms

	rjmp ProgramLoop

;/********************* Subroutines */


;/********************** GPIO Inits */

initGPIO:

	push r16
										; Output
	ser r16								; set all bits in register
	out DDRB, r16						; entire PORTB set to output

	pop r16

ret

;/********************************* GPIO Test */


testGPIO:

	PUSH r18
	PUSH r17
	PUSH r16

	; Flash PortB a few times

	clr r16
	BlinkLoop:

		ldi XL, low(500)
		ldi XH, high(500)

		ser r17
		out PORTB, r17
		rcall Delay_ms
		clr r17
		out PORTB, r17
		rcall Delay_ms

		inc r16
		cpi r16, 0x2
		brlt BlinkLoop

	ldi r18, 0
	RepeatShifts:						; Traverse the port a few times

	ldi r16, (1 << 0)
	ldi r17, 0

	ldi XL, low(100)
	ldi XH, high(100)


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
	out PORTB, r17					 ; turn it off

	POP r16
	POP r17
	POP r18

ret




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

