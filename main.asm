;
; INTERRUPTELEVADOR.asm
;
; Created: 30/07/2019 13:39:13
; Author : rodol
;
.include "./m328Pdef.inc" ; ATIVANDO O USO DE LABELS PARA O FÁCIL ENTENDIMENTO

; --------- DEFININDO CONSTANTES -----------
.equ UBRRvalue = 103
.equ ClockMHz = 16
.equ DelayMs = 20

; --------- CONFIGURANDO REGISTRADORES -----------
.def led = r10;falta registrador
.def buzzer = r11;falta registrador
.def temp = r16
.def porthistory = r17
.def aux = r18
.def nextMove = r19
.def position0 = r20
.def position1 = r21
.def position2 = r22
.def indexArray = r24
.def sizeStack = r25
.def porta = r26;falta botar o estado da porta
.def count = r27
.def atual = r28
.def incStack = r31
; Registradores r13, r14 e r15 estão sendo usados na função delay
; ---------  ------------------------  -----------
;
; --------- CONFIGURANDO INTERRUPÇÕES -----------	
	.org 0x00
	jmp reset

	.org INT0addr  ; Area responsável pelo INT0
	jmp HANDLE_int0 ; Pular para ISR respectiva
	.org INT1addr  ; Area responsável pelo INT1
	jmp HANDLE_int1 ; Pular para ISR respectiva

	.org 0x0006 ; Área responsável pelo PCINT0
	jmp HANDLE_PCINT2 ; Pular para ISR respectiva (PCMSK2) 
	.org 0x0008 ; Área responsável pelo PCINT1
	jmp HANDLE_PCINT1 ; Pular para ISR respectiva (PCMSK1) 
	.org 0x000A ; Área responsável pelo PCINT2
	jmp HANDLE_PCINT0 ; Pular para ISR respectivas (PCMSK0) 

; ----- ------- DELAY FUNCTION -----------
delay20ms:
	ldi r16,byte3(ClockMhz * 1000 * DelayMs /1)
	ldi r18,high(ClockMhz * 1000 * DelayMs /1)
	ldi r23,low(ClockMhz * 1000 * DelayMs /1)

	subi r23,1
	sbci r18,0
	sbci r16,0
	brcc pc-3
	
	ret
; ----------- ACIONAR TIMER -------------
	.org OC1Aaddr
	rjmp timer_move
	.org OC1Baddr
	rjmp timer_buzzer
;-----------------------------------------

reset:
	;----------- Inicializacao dos timers -------------
	;Timer Porta
	#define CLOCK 16.0e6 	;clock speed
	.equ PRESCALE = 0b101 	;/256 prescale
	.equ PRESCALE_DIV = 1024
	#define DELAY 0.003 		;seconds
	.equ WGM = 0b0100		;Waveform generation mode: CTC
	;(you must ensure this value of TOP is between 0 and 65535)
	.equ TOP = int(0.5 + ((CLOCK/PRESCALE_DIV)*DELAY))
	.if TOP > 65535
	.error "TOP is out of range"
	.endif
	ldi temp, high(TOP) 		;initialize compare value (TOP)
	sts OCR1AH, temp
	ldi temp, low(TOP)
	sts OCR1AL, temp
	
	;Timer Andar
	#define DELAY2 0.0025 ;seconds
	;(you must ensure this of TOP2 value is between 0 and 65535)
	.equ TOP2 = int(0.5 + ((CLOCK/PRESCALE_DIV)*DELAY2))
	.if TOP2 > 65535
	.error "TOP is out of range"
	.endif
	ldi temp, high(TOP2) 		;initialize compare value (TOP)
	sts OCR1BH, temp
	ldi temp, low(TOP2)
	sts OCR1BL, temp
	;-----------------------------------------
	;Iniciar timer
	ldi temp, ((WGM&0b11) << WGM10)		;lower 2 bits of WGM
	sts TCCR1B, temp
	ldi temp, ((WGM>> 2) << WGM12)|(PRESCALE << CS10)
	sts TCCR1B, temp 				;start counter
	
	;incia a interrupção
	lds temp, TIMSK1
	ori temp, 0b1
	sts TIMSK1, temp
	sei
	;-----------------------------------------
	
	; --------- CONFIGURANDO USART -----------
	.cseg
	ldi temp, high (UBRRvalue) ;baud rate
	sts UBRR0H, temp
	ldi temp, low (UBRRvalue)
	sts UBRR0L, temp
	ldi temp, (3<<UCSZ00)
	sts UCSR0C, temp
	ldi temp, (1<<RXEN0)|(1<<TXEN0)
	sts UCSR0B, temp; 

	; --------- CONFIGURANDO STACK -----------
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	; --------- CONFIGURANDO INTERRUPÇÕES EXTERNAS -----------

	clr temp
	ldi temp, (1<<PORTB1)|(1<<PORTB0)
	out PORTB,temp
	clr temp
	ldi temp, (0<<DDB0)|(0<<DDB1)|(1<<DDB2)|(1<<DDB3)
	out DDRB,temp
	
	clr temp
	ldi temp, (1<<PORTC2)|(1<<PORTC3)
	out PORTC,temp
	clr temp
	ldi temp, (0<<DDC2)|(0<<DDC3)
	out DDRC,temp

	clr temp
	ldi temp, (1<<PORTD4)|(1<<PORTD5)
	out PORTD,temp
	clr temp
	ldi temp, (0<<DDD4)|(0<<DDD5)|(1<<DDD0)|(1<<DDD1)
	out DDRD,temp

	clr temp 
	ldi temp, (1<<PCIE2)|(1<<PCIE1)|(1<<PCIE0) ; Habilitando interrupções por PCINTx
	sts PCICR, temp

	;Abaixo 'ligamos' os pinos PCINTx que queremos
	clr temp
	ldi temp, (1<<PCINT21)|(1<<PCINT20) ; PCINT20 = PD4 e PCINT21 = PD5
	sts PCMSK2, temp ; Registrador onde contén PCINTx (16-23)

	clr temp
	ldi temp, (1<<PCINT11)|(1<<PCINT10) ; PCINT10 = PC2 e PCINT11 = PC3
	sts PCMSK1, temp  ; Registrador onde contén PCINTx (8-14)
	
	clr temp
	ldi temp, (1<<PCINT1)|(1<<PCINT0) ; PCINT0 = PB0 e PCINT1 = PB1
	sts PCMSK0, temp ; Registrador onde contén PCINTx (7-0)

	; --------- CONFIGURANDO INTERRUPÇÕES INTERNAS -----------

	clr temp
	ldi temp, (1<<ISC11)|(1<<ISC10)|(1<<ISC01)|(1<<ISC00) 
	sts EICRA, r16 

	clr temp
	ldi temp, (1<<INT0)|(1<<INT1)
	out EIMSK, r16
	
	;---------------------- INICIAR VARIAVEIS ----------------------
	
	ldi porta, 0
	ldi count, 0
	ldi atual, 0

	ser porthistory; Setando tudo para comparação (Usado na idf. dos PCINT)
	sei ; Ativa as interrupções globais

	; -------------------- ------------------ ----------------------







; ---------------------- MAIN ----------------------
main:
	sei
	jmp main		
;----------------------       ---------------------- 







; -------------------- TRATANDO INTERRUPÇÕES ----------------------
HANDLE_int0: ;ABRIR A PORTA
	rcall delay20ms ; Lidando com Bouncing
	rjmp open_door
	reti

HANDLE_int1: ; FECHAR A PORTA
	rcall delay20ms ; Lidando com Bouncing
	rjmp close_door
	reti

HANDLE_PCINT0: ; Vai Lidar com PORTD
	rcall delay20ms ; Lidando com Bouncing

	;----- Artimanha para saber qual botão foi pressionado -----
	clr temp ; Zera 'temp'
	in temp, PIND ; Copia PIND
	eor temp,porthistory ; Como 'porthistory' é todo 1's o XOR retornará 0 em temp caso forem iguais
	in porthistory, PIND  ; Faz uma cópia de PIND para porthistory
	clr aux
	ldi aux,1<<PIND4
	and temp, aux ;  Se 'temp' for '1' PD4 foi ativo
	; ----- ----- ----- ----- ----- ----- ----- ----- -----

	cpi temp, 0x0 ; Compara 'aux' com 1
	breq INTERRUPT_PIND4 ; Se igual, segue o branch

	;--AQUI VAI INTERRUPÇÃO PRA DESCER PARA O TÉRREO APERTANDO INTERNAMENTE
	ldi nextMove,0 ;Chama Térreo
	call printMove
	jmp move_elevator
	jmp end

	INTERRUPT_PIND4:
	;--AQUI VAI INTERRUPÇÃO PRA DESCER PARA O TÉRREO APERTANDO EXTERNAMENTE
	
	ldi nextMove,0 ;Chama Térreo
	call printCall
	jmp call_elevator
	
	end:
	reti

HANDLE_PCINT1: ; Vai Lidar com PORTC
	rcall delay20ms ; Lidando com Bouncing

	;----- Artimanha para saber qual botão foi pressionado -----
	clr temp ; Zera 'temp'
	in temp, PINC ; Copia PINC
	eor temp,porthistory ; Como 'porthistory' é todo 1's o XOR retornará 0 em temp caso forem iguais
	in porthistory, PINC  ; Faz uma cópia de PINC para porthistory
	clr aux
	ldi aux,1<<PINC2
	and temp, aux ;  Se 'temp' for '1' PC2 foi ativo
	; ----- ----- ----- ----- ----- ----- ----- ----- -----
	
	cpi temp, 0x0 ; Compara 'aux' com 1
	breq INTERRUPT_PINC2 ; Se igual, segue o branch
	;--AQUI VAI INTERRUPÇÃO PRA SUBIR PARA O 1 ANDAR APERTANDO INTERNAMENTE

	ldi nextMove,1 ;Chama 1 andar
	call printMove
	jmp move_elevator
	jmp end1

	INTERRUPT_PINC2:
	;--AQUI VAI INTERRUPÇÃO PRA SUBIR PARA O 1 ANDAR APERTANDO EXTERNAMENTE
	ldi nextMove,1 ;Chama 1 andar
	call printCall
	jmp call_elevator

	end1:
	reti

HANDLE_PCINT2: ; Vai Lidar com PORTB
	rcall delay20ms ; Lidando com Bouncing

	;----- Artimanha para saber qual botão foi pressionado -----
	clr temp ; Zera 'temp'
	in temp, PINB ; Copia PINB
	eor temp,porthistory ; Como 'porthistory' é todo 1's o XOR retornará 0 em temp caso forem iguais
	in porthistory, PINB  ; Faz uma cópia de PINB para porthistory
	clr aux
	ldi aux,1<<PINB1
	and temp, aux ;  Se 'temp' for '1' PB1 foi ativo
	; ----- ----- ----- ----- ----- ----- ----- ----- ----- 
	
	cpi temp, 0x0 ; Compara 'aux' com 1
	breq INTERRUPT_PINB1 ; Se igual, segue o branch
	;-- GABRIEL AQUI VAI INTERRUPÇÃO PRA SUBIR PARA O 2 ANDAR APERTANDO INTERNAMENTE
	ldi nextMove,2 ;Chama 2 andar
	call printMove
	jmp move_elevator
	jmp end2

	INTERRUPT_PINB1:
    ;-- GABRIEL AQUI VAI INTERRUPÇÃO PRA SUBIR PARA O 2 ANDAR APERTANDO EXTERNAMENTE
	ldi nextMove,2 ;Chama 2 andar
	ldi temp, 67
	rcall print
	jmp call_elevator

	end2:
	reti


; -------------------- FUNÇÕES ESSENCIAIS ----------------------
call_elevator: ;BOTÃO DE FORA 

	ldi aux, 0
	
	cpi sizeStack, 0
	brne while
	push nextMove
	inc sizeStack

	lds temp, TIMSK1
	ori temp, 0b011	
	sts TIMSK1, temp
	rjmp main

while:;pegar os valores da pilha e lojar no array
	cp aux, sizeStack; comparação 
	brge endWhile; brge  aux >= sizeStack, fim do while
	mov indexArray, aux ; indexArray recebe valor de auxiliar
	pop temp; retiramos o valor da pilha e colocamos em temp 
	rcall setArray; na posição indexArray setamos a o array com o valor de temp, valo que retiramos da pilha
	inc aux; incrementando aux
	rjmp while; laço do while

endWhile:
	ldi aux, 0

while2:;empilhar valores maiores que nextmove e por fim empilhar nextmove
	cp aux, sizeStack
	brge endWhile2; verificar se aux >= sizeStack
	mov indexArray, aux; passa o valor de aux para indexarray
	rcall getArray; coloca o valor de array[indexArray] em temp
	cp nextMove, temp
	brlt empilharGetArray; verificar se nextmove < temp
	push nextMove; coloca nextmove na pilha
	rjmp endWhile2; sai do while
	empilharGetArray:; empilhar o valor que ta em temp, que o valor que estava no array
	push temp
	inc aux; incrementa aux
	rjmp while2; laço

endWhile2:
	ldi incStack,1

while3://empilhar valores menores que nextmove, e igonorar ocorrencia do mesmo na hora de empilhar
	cp aux, sizeStack; aqui não alteramos aux para 0, para continuar de onte parou o while anterior, 
	;tendo em vistas que os valores maiore que nextmove ja colocados
	;na pilha não precisam ser verificados novamente
	brge endWhile3; aux maior igual a sizeStack
	mov indexArray, aux; indexarray recebe aux
	rcall getArray; temp = array[indexArray]
	cp nextMove, temp
	brne empilharGetArray2; nextmove != temp
	; nextmove == temp; ignoramos temp e decrementamos o tamalho da pilha
	ldi incStack, 0
	inc aux
	rjmp while3;

empilharGetArray2:
	push temp; empilha temp
	inc aux; incrementa aux
	rjmp while3; laço

endWhile3:
	add sizeStack, incStack
	;precisamos inverter a pilha, pois no ultimo passo a pilha fica invertida
	ldi aux, 0

while4:
	cp aux, sizeStack
	brge endWhile4
	pop temp
	mov indexArray, aux
	rcall setArray
	inc aux
	rjmp while4
	
endWhile4:
	ldi aux, 0

while5:
	cp aux, sizeStack
	brge endWhile5
	mov indexArray, aux
	rcall getArray
	push temp
	inc aux
	rjmp while5

endWhile5:
	lds temp, TIMSK1
	ori temp, 0b011	
	sts TIMSK1, temp
	rjmp main

getArray:
	cpi indexArray, 0
	brne index1get
	mov temp, position0
	ret
	
	index1get: 
	cpi indexArray, 1
	brne index2get
	mov temp, position1
	ret

	index2get:
	cpi indexArray, 2
	brne endget
	mov temp, position2
	ret
	
endget:
	ret

setArray:
	cpi indexArray, 0
	brne index1set
	mov position0, temp
	ret
	
index1set: 
	cpi indexArray, 1
	brne index2set
	mov  position1, temp
	ret

index2set:
	cpi indexArray, 2
	brne endset
	mov  position2, temp
	ret
	
	endset:
	ret

print:
	lds aux, UCSR0A
	sbrs aux, UDRE0
	rjmp print
	sts UDR0, temp
	reti

printCall:
	ldi temp,67
	call print
	ldi temp,97
	call print
	ldi temp,108
	call print
	ldi temp,108
	call print
	mov temp, nextMove
	subi temp, -48
	call print
	ldi temp, 8
	call print
	reti


printMove:
	ldi temp, 77
	call print
	ldi temp,111
	call print
	ldi temp,118
	call print
	ldi temp,101
	call print
	mov temp, nextMove
	subi temp, -48
	call print
	ldi temp, 8
	call print
	reti



finish:
	break

;-----------------------------------------------------

move_elevator: ;BOTÃO DE DENTRO
	cpi sizeStack, 0; pilha vazia
	brne skip1; 
	push nextMove
	inc sizeStack
	
	lds temp, TIMSK1
	ori temp, 0b011	
	sts TIMSK1, temp
	rjmp main


skip1:
	pop position0;retira valor da pilha compara se next é igual ao valor retirado se sim so coloca o valor novamente
	dec sizeStack
	cp position0, nextMove
	brne skip2 
	push nextMove
	inc sizeStack
	
	lds temp, TIMSK1
	ori temp, 0b011	
	sts TIMSK1, temp
	rjmp main

skip2:
	cpi sizeStack, 0; se os valores forem diferentes verifica se pilha está vazia, se sim empilha os dois 
	brne skip3
	push nextMove
	inc sizeStack
	push position0
	inc sizeStack
	
	lds temp, TIMSK1
	ori temp, 0b011	
	sts TIMSK1, temp
	rjmp main

skip3:; pilha não vazia, faz mais um pop
	pop position1
	dec sizeStack
	cp position1, nextmove
	brne skip4; se valor retirado diferente 
	push nextMove
	inc sizeStack
	push position0
	inc sizeStack
	
	lds temp, TIMSK1
	ori temp, 0b011	
	sts TIMSK1, temp
	rjmp main

skip4:
	cpi sizeStack, 0
	brne skip5
	push nextMove
	inc sizeStack
	push position1
	inc sizeStack
	push position0
	inc sizeStack

	lds temp, TIMSK1
	ori temp, 0b011	
	sts TIMSK1, temp
	rjmp main

skip5:
	lds temp, TIMSK1
	ori temp, 0b011	
	sts TIMSK1, temp
	rjmp main

;------------------------------------------------------

setDisplay:
	cpi temp, 0
	brne displaySet1
	ldi temp, 0b00000000
	sts 0x25, temp
	ret

displaySet1:
	cpi temp, 1
	brne displaySet2
	ldi temp, 0b00000100
	sts 0x25, temp
	ret

displaySet2:
	cpi temp, 2
	brne displaySet3
	ldi temp, 0b00001000
	sts 0x25, temp

displaySet3:
	ret  


;-----------MUDOU O ANDAR CHAMA ESSE TIMER-------------;
timer_move:
	rjmp open_door
	reti
;----------DEPOIS QUE CHEGOU NO ANDAR E NÃO APERTOU BOTÃO ESPERA 5s E TOCA O BUZZER----------------;
timer_buzzer:
	cpi count, 1
	breq toca_buzz
	cpi count, 3
	breq desliga_tudo
	inc count
	reti
	
toca_buzz:
	;liga buzz
	push temp
	in temp, SREG 
	push temp 
	ldi temp, (1<<PORTC1)
	out PORTC, temp
	pop temp 
	out SREG, temp 
	pop temp
		
	inc count
	reti
	
desliga_tudo:
	rcall close_door
	ldi count,0
	reti

close_door:
	ldi porta, 0
	;DEVE PRINTAR ALGO
	;usando o temp
	push temp
	in temp, SREG 
	push temp 
	
	;DESLIGA O LED
	ldi temp, (0<<PORTC0)
	out PORTC, temp
	
	;DESLIGA O BUZZ
	ldi temp, (0<<PORTC1)
	out PORTC, temp
	
	pop temp 
	out SREG, temp 
	pop temp
	
	;DESLIGANDO O TIMER
	;salvando o que tem no temp para não perder
	push temp
	in temp, SREG 
	push temp 
	;a tarefa da interrupção ;entra aqui 
	;ativa a interrupção de 5s e 10s
	lds temp, TIMSK1
	ori temp, 0b001
	sts TIMSK1, temp
	;devolve as coisas para o temp
	pop temp 
	out SREG, temp 
	pop temp
	;sai da func
	reti

open_door:
	;verifica se está andando
	cp atual, nextMove
	brne nada
	;abre a porta
	ldi porta, 1
	;salvando o que tem no temp para não perder
	push temp
	in temp, SREG 
	push temp 
	;LIGA O LED
	ldi temp, (1<<PORTC0)
	out PORTC, temp
	;a tarefa da interrupção ;entra aqui 
	;ativa a interrupção de 5s e 10s
	lds temp, TIMSK1
	ori temp, 0b101
	sts TIMSK1, temp
	;devolve as coisas para o temp
	pop temp 
	out SREG, temp 
	pop temp
	
	;sai da func
	nada: 
		nop
	ret


