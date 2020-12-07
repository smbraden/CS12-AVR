;/*-------------------------------------------------------------------------------------//
;	Project:			template
;	Filename:           template.S
;	Author:				author
;	Date:               system_date_time
;	Device:				ATmega328A
;	Device details:		1MHz internal clock, 8-bit CPU, Vcc = 5 volts
;
;	Description:		Blinky program template
;	Circuit:			PORTB wired to set of LEDs w/ protective resistances
;//-------------------------------------------------------------------------------------*/

.NOLIST								; Don't list the following in the list file
.INCLUDE	"../includes/m328def.inc"
.LIST								; Switch list on again

.EQU		F_CPU = 1000000			; 1MHz Internal RC clock
.EQU		TRUE = 0x01
.EQU		FALSE = 0x00

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
	
	ldi r18, (1 << PB5)
	ldi XL, low(500)
	ldi XH, high(500)

	;/************** Begin Program Loop */
	
	ProgramLoop:

		in r17, PORTB
		eor r17, r18
		out PORTB, r17
		rcall Delay_ms_word

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

	PUSH r27
	PUSH r26
	PUSH r19
	PUSH r18
	PUSH r17
	PUSH r16

	; Flash PortB a few times

	clr r16
	BlinkLoop:

		ldi XL, low(500)
		ldi XH, high(500)				; ~500 ms delay

		ser r17
		out PORTB, r17
		rcall Delay_ms_word
		clr r17
		out PORTB, r17
		rcall Delay_ms_word

		inc r16
		cpi r16, 0x2
		brlt BlinkLoop

	ldi r18, 0
	ldi r16, 100						; ~100 ms delay
	RepeatShifts:						; Traverse the port a few times

	ldi r19, (1 << 0)
	ldi r17, 0

	LeftShiftLoop:
		out PORTB, r19
		lsl r19
		rcall Delay_ms_byte
		inc r17
		cpi r17, 7
	brlt LeftShiftLoop

	RightShiftLoop:
		out PORTB, r19
		lsr r19
		rcall Delay_ms_byte
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
	POP r19
	POP r26
	POP r27

ret



;/******************** Lib Includes */

.INCLUDE "../includes/Delay.inc"