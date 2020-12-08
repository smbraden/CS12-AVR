/*-------------------------------------------------------------------------------------//
    Project:			Dimmer_Linear
	Filename:           Dimmer_Linear.asm
    Author:				Sonja Braden
    Date:               12/02/2020
	Device:				ATmega328A
	Device details:		1MHz internal clock, 8-bit CPU, Vcc = 5 volts
    
	Description:		Continuously measures light intensity, and uses PWM to dim/brighten
						an LED display in response to adjusting a potentiometer knob.
						A button is used to turn off/on the lights completely by 
						putting the CPU to sleep or waking it up
						This is a brute force approach, to contrast the program, Dimmer

	Circuit:			PORTB pins (PB0 - PB7) are wired to LEDS in order 0 - 7.
						PC0 (ADC0) is wired to the node of a voltage divider, which 
						consists of ~1 kOhm potenitometer tied from  Vcc to divider,
						and a constant resistance of ~220Ohm from ground to divider.
						PD3 is wired to button that brings the PD3 pin high when pushed.
//-------------------------------------------------------------------------------------*/

.NOLIST								; Don't list the following in the list file
.INCLUDE	"m328def.inc"			; 
.LIST								; Switch list on again

.DEVICE		ATmega328				; The target device type (actually using ATmega328A)

.EQU		F_CPU = 1000000			; 1MHz Internal RC clock
.EQU		DEFAULT_DELAY = 400		; (*) 100 - 400 good range
.EQU		TRUE = 0x01
.EQU		FALSE = 0x00

.DEF		SLEEP_IDLE = r20		; don't use r20 anywhere else

/******************** SRAM defines */

.DSEG
.ORG SRAM_START
; Format: Label: .BYTE N ; reserve N Bytes from Label:

/********* Reset/Interrupt Vectors */

.CSEG								; lets the assembler switch output to the code section
.ORG		0x0000					; next instruction written to address 0x0000
									; first instruction of an executable always located at address 0x0000
	jmp Reset				; RESET
	jmp EXT_INT0			; INT0
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


/******************** Reset Routine */

Reset:								
    
	/**************** Initialize Stack */

	ldi r16, HIGH(RAMEND)				
	out SPH, r16						; SPH = Stack Pointer High
	ldi r16, LOW(RAMEND)		
	out SPL, r16						; SPL = Stack Pointer Low

	/**************** Initialize other */

	call initGPIO
	call initADC0
	call testGPIO
	call initSleepMode
	call InitInterrupts

	/************** Begin Program Loop */

	ldi XL, low(DEFAULT_DELAY)
	ldi XH, high(DEFAULT_DELAY)

	ProgramLoop:
		
		cpi SLEEP_IDLE, TRUE
		brne SkipSleep
		sleep

		SkipSleep:

		ldi r16, 0						; read channel 0
		rcall readADC

		lds r16, ADCH

		rcall Square_nibble				; squaring the most significant nibble
										; creates more light contrast
		ser r17							; (*) all on PORTB
		out PORTB, r17					; toogle all output on PORTB
		
		rcall Delay_us_byte
		
		clr r17			
		out PORTB, r17					

		rcall Delay_us_word				; delay for DEFAULT_DELAY 
		
	rjmp ProgramLoop

/********************* Subroutines */


/********************** GPIO Inits */

initGPIO:

	push r17
	push r16

										; Output 
	ser r16								; set all bits in register
	out DDRB, r16						; entire PORTB set to output
	
										; Voltage sensor
	cbi DDRC, PC0						; PC0 set to input
	sbi PORTC, PC0						; activaate pull-up resistors

										; Button
	ldi r16, (1 << PD2)					; bit mask PD2
	in r17, DDRD						; snapshot of register
	or r17, r16							; bit mask PD2 & former register state
	out DDRD, r17						; PD2 set to input

	in r17, PORTB						; snapshot of register
	or r17, r16							; bit mask PD2 & former register state
	out PORTB, r17						; PD2 pull-up resistors set

	pop r16
	pop r17

ret




/********************** ADC Inits */

initADC0:

	push r15
	push r16

	ldi r16, (1 << REFS0)			; set REFS0 bit without disturbing other bits
	lds r15, ADMUX
	or r15, r16
	ldi r16, (1 << REFS1)			; clear REFS1 bit without disturbing other bits
	com r16
	and r15, r16
	sts ADMUX, r15					; Voltage Ref set to AVCC w/ external cap at AREF pin


	ldi r16, (1 << ADLAR)			
	lds r15, ADMUX
	or r15, r16
	sts ADMUX, r15					; left-adjusted conversion in the ADCH:ADCL
	

	ldi r16, (1 << ADPS1)
	lds r15, ADCSRA
	or r15, r16
	sts ADCSRA, r15					; ADCSRA |= (1 << ADPS1) ADC prescalar division factor set to 4

	ldi r16, (1 << ADEN)
	sts ADCSRA, r16					; Set ADC enable bit

	pop r16
	pop r15

ret



/******************* Prep for Idle Sleep mode */

initSleepMode:
	push r16

	ldi r16, 0x0E | (1 << SE)			; idle sleep mode, and sleep enable bit
	out SMCR, r16
	
	ldi SLEEP_IDLE, FALSE

	pop r16

ret

/********************************* GPIO Test */

testGPIO :
	
	; PUSH r27
	; PUSH r26
	PUSH r19
	PUSH r18
	PUSH r17
	PUSH r16
	
	; Flash PortB a few times
	/*
	clr r16
	BlinkLoop:
		
		ldi XL, low(500)
		ldi XH, high(500)

		ser r17
		out PORTB, r17
		rcall Delay_ms_word
		clr r17
		out PORTB, r17
		rcall Delay_ms_word

		inc r16
		cpi r16, 0x2
		brlt BlinkLoop
	*/

	ldi r16, 100
	ldi r18, 0
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
	; POP r26
	; POP r27

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

	loopUntilClear:						; ADCSRA out of range for sbic command
		lds r18, ADCSRA
		cp r18, r17
			breq exit
		rjmp loopUntilClear

	exit:

	POP r18
	POP r17

ret

/********************** Square Byte */

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


/******************** Square a Nibble */

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






/***************** Interrupt Inits */
InitInterrupts:
	
	push r16
	
	ldi r16, (1 << ISC00)| (1 << ISC01)			
	sts EICRA, r16						;  rising edge of INT0 generates an interrupt request
	
	ldi r16, (1 << INT0)				
	out EIMSK, r16						;  external pin interrupt is enabled

	sei									; Set Global Interrupt Enable Bit
	pop r16
ret



/****** Interrupt service routines */

EXT_INT0:
								
	push r19							; save register on stack
	push r17
	in r17, SREG						; save flags

	ldi r19, 10							; ~10ms debouncing delay
	debounceLoop:
		subi r19, 1
		brne debounceLoop
	
	ldi r19, TRUE
	eor SLEEP_IDLE, r19

	out SREG, r17						; restore flags
	pop r17
	pop r19
	
RETI								; end of service routine 1





;/************* Parameterized Delays */

; Pre:		r27:r26 contains the number of milliseconds
Delay_ms_word:

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




; Pre:		r16 contains the number of milliseconds
Delay_ms_byte:

	push r16
	push r17
	push r18	

	ldi r18, 100
	ldi r17, 10
	milliLoop_b:
	
		microLoop1_b:
		subi r18, 1
		brne microLoop1_b

		microLoop2_b:
		subi r17, 1
		brne microLoop2_b
		
		subi r16, 1
		brne milliLoop_b
	
	pop r18
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