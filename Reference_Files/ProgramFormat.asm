;
; ********************************************
; * [Add Project title here] *
; * [Add more info on software version here] *
; * (C)20xx by [Add Copyright Info here] *
; ********************************************
;
; Included header file for target AVR type
.NOLIST
.INCLUDE "tn13def.inc" ; Header for ATTINY13
.LIST
;
; ============================================
; H A R D W A R E I N F O R M A T I O N
; ============================================
;
; [Add all hardware information here]
;
; ============================================
; P O R T S A N D P I N S
; ============================================
;
; [Add names for hardware ports and pins here]
; Format: .EQU Controlportout = PORTA
; .EQU Controlportin = PINA
; .EQU LedOutputPin = PORTA2
;
; ============================================
; C O N S T A N T S T O C H A N G E
; ============================================
;
; [Add all constants here that can be subject
; to change by the user]
; Format: .EQU const = $ABCD
;
; ============================================
; F I X + D E R I V E D C O N S T A N T S
; ============================================
;
; [Add all constants here that are not subject
; to change or calculated from constants]
; Format: .EQU const = $ABCD
;
; ============================================
; R E G I S T E R D E F I N I T I O N S
; ============================================
;
; [Add all register names here, include info on
; all used registers without specific names]
; Format: .DEF rmp = R16
.DEF rmp = R16 ; Multipurpose register
;
; ============================================
; S R A M D E F I N I T I O N S
; ============================================
;
.DSEG
.ORG 0X0060
; Format: Label: .BYTE N ; reserve N Bytes from Label:
;
; ============================================
; R E S E T A N D I N T V E C T O R S
; ============================================
;
.CSEG
.ORG $0000
 rjmp Main ; Reset vector
 reti ; Int vector 1
 reti ; Int vector 2
 reti ; Int vector 3
 reti ; Int vector 4
 reti ; Int vector 5
 reti ; Int vector 6
 reti ; Int vector 7
 reti ; Int vector 8
 reti ; Int vector 9
;
; ============================================
; I N T E R R U P T S E R V I C E S
; ============================================
;
; [Add all interrupt service routines here]
;
; ============================================
; M A I N P R O G R A M I N I T
; ============================================
;
Main:
; Init stack
 ldi rmp, LOW(RAMEND) ; Init LSB stack
 out SPL,rmp
; Init Port B
 ldi rmp,(1<<DDB2)|(1<<DDB1)|(1<<DDB0) ; Direction of Port B
 out DDRB,rmp
; [Add all other init routines here]
 ldi rmp,1<<SE ; enable sleep
 out MCUCR,rmp
 sei
;
; ============================================
; P R O G R A M L O O P
; ============================================
;
Loop:
 sleep ; go to sleep
 nop ; dummy for wake up
 rjmp loop ; go back to loop
;
; End of source code
;
