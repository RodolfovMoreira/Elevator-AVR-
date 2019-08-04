;
; AssemblerApplication3.asm
;
; Created: 04/08/2019 07:53:59
; Author : rodol
;


; REMEMBER THAT WHEN THE BUTTON IN B0 IS PRESSED, IT TRIGGERS THE INTERRUPTION ON PIN CHANGE! PCINTX PINS ONLY ALLOW TO TRIGGER IN PINCHANGE!
.include "./m328Pdef.inc" 

.equ ClockMHz = 16
.equ DelayMs = 20

.def temp = r16
.def aux = r17 ;keep track of pushbutton


.org 0x00
jmp reset
.org 0x0006 ; Área responsável pelo PCINT0
jmp HANDLE_PCINT2 ; Pular para ISR respectiva (PCMSK2) 

delay20ms:
	ldi r22,byte3(ClockMhz * 1000 * DelayMs /5)
	ldi r21,high(ClockMhz * 1000 * DelayMs /5)
	ldi r20,low(ClockMhz * 1000 * DelayMs /5)

	subi r20,1
	sbci r21,0
	sbci r22,0
	brcc pc-3
	
	ret

reset:

ser r16							
out DDRB, r16	
clr temp
out PORTD,temp

clr temp
ldi temp, (1<<PORTB0)
out PORTB,temp
clr temp
ldi temp, (0<<DDB0)
out DDRB,temp

clr temp ; Zera 'temp'
ldi temp,(1<<PCIE0) ; Habilitando interrupções por PCINTx
sts PCICR, temp

clr temp ; Zera 'temp'
ldi temp,(1<<PCINT0) ; PCINT0 = PB0 e PCINT1 = PB1
sts PCMSK0, temp ; Registrador onde contén PCINTx (7-0)

clr r18
clr aux
ser temp
sei

main:
	rjmp main
;----- HANDLE PCINT2 -----
HANDLE_PCINT2:
	rcall delay20ms
	rcall delay20ms
	rcall delay20ms
	cpi aux,0xFF
	brne CONTINUE
	ldi aux,0x00
	reti
CONTINUE:
	eor r18,temp
	out PORTD,r18
	rcall delay20ms
	ldi aux,0xFF
	reti
;----- ----- ----- -----
