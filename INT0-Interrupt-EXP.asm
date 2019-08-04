;
; AssemblerApplication3.asm
;
; Created: 04/08/2019 07:53:59
; Author : rodol
;


; Replace with your application code
.include "./m328Pdef.inc" 
.def temp = r16


.org 0x00
jmp reset
.org INT0addr  ; Area responsável pelo INT0
jmp HANDLE_int0 ; Pular para ISR respectiva


reset:

;DDRD &= ~(1 << DDD2);     // Clear the PD2 pin
;    // PD2 (PCINT0 pin) is now an input

clr temp
;ldi temp, (1<<DDD2)
out DDRD, temp
;    PORTD |= (1 << PORTD2);    // turn On the Pull-up
;    // PD2 is now an input with pull-up enabled

clr temp
ldi temp,(1<<PORTD2)
out PORTD,temp

ser r16							
out DDRB, r16	
clr temp
out PORTB,temp
;	 EICRA |= (1 << ISC00);    // set INT0 to trigger on ANY logic change
;    EIMSK |= (1 << INT0);     // Turns on INT0

clr temp
ldi temp,(1<<ISC00)|(1<<ISC01)
sts EICRA,temp

clr temp
ldi temp,(1<<INT0)
out EIMSK,temp


clr r18
ser temp
sei

main:
	rjmp main

HANDLE_int0:
	
	eor r18,temp
	out PORTB,r18
	reti
