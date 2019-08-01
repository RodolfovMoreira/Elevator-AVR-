;
; INTERRUPTELEVADOR.asm
;
; Created: 30/07/2019 13:39:13
; Author : rodol
;
.include "./m328Pdef.inc" ; ATIVANDO O USO DE LABELS PARA O FÁCIL ENTENDIMENTO
.equ UBRRvalue = 103
.def temp = r16
.def porthistory = r17
.def aux = r18

;.def temp = r16
.def sizeStack = r25
.def nextMove = r19
.def position0 = r20
.def position1 = r21
.def position2 = r22
.def auxLoop = r23
;.def aux = r25
.def indexArray = r24
.def incStack = r31



	
	.org 0x00
	jmp reset
; --------- CONFIGURANDO INTERRUPÇÕES -----------
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

print:
	lds aux, UCSR0A
	sbrs aux, UDRE0
	rjmp print
	sts UDR0, temp
	ret

printAll:
	cpi sizeStack, 0
	brge printPilha
	rjmp finish
	printPilha:
	pop temp
	subi temp, -48
	dec sizeStack
	rcall print
	rjmp printAll

finish:
	break


reset:
	ldi temp,65
	rcall print

	.cseg
;initialize USART
ldi temp, high (UBRRvalue) ;baud rate
sts UBRR0H, temp
ldi temp, low (UBRRvalue)
sts UBRR0L, temp
ldi temp, (3<<UCSZ00)
sts UCSR0C, temp
ldi temp, (1<<RXEN0)|(1<<TXEN0)
sts UCSR0B, temp; 

	;Stack initialization
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp


	clr temp
	ldi temp, (1<<PORTB1)|(1<<PORTB0)
	out PORTB,temp
	clr temp
	ldi temp, (1<<DDB0)|(1<<DDB1)
	out DDRB,temp
	
	clr temp
	ldi temp, (1<<PORTC2)|(1<<PORTC3)
	out PORTC,temp
	clr temp
	ldi temp, (1<<DDC2)|(1<<DDC3)
	out DDRC,temp

	clr temp
	ldi temp, (1<<PORTD4)|(1<<PORTD5)
	out PORTD,temp
	clr temp
	ldi temp, (1<<DDD4)|(1<<DDD5) ;0x00111000
	out DDRD,temp

	clr temp ; Zera 'temp'
	ldi temp, (1<<ISC11)|(1<<ISC10)|(1<<ISC01)|(1<<ISC00) ; Controle para gerar a interrupção quando for borda de descida no INT1 e INT0
	sts EICRA, r16 ; Carrega no registrador de interrupções externas

	clr temp ; Zera 'temp'
	ser temp ; Seta todos os bits '1'
	;out EIMSK, r16 ; Carrega no registrador que 'liga' INT0 e INT1

	;Checar a necessidade do codigo abaixo
	clr temp ; Zera 'temp'
	ldi temp, (1<<INTF1)|(1<<INTF0)
	out EIFR,temp
	; O vetor EIFR possui somente INTF1 E INTF0 onde
	; caso ocorra uma interrupção ele seta o respectivo 
	; lugar para identificação, porém não entendi o motivo de setar desde logo
	;------------------------------

	clr temp ; Zera 'temp'
	ldi temp, (1<<PCIE2)|(1<<PCIE1)|(1<<PCIE0) ; Habilitando interrupções por PCINTx
	sts PCICR, temp

	;----Abaixo 'ligamos' os pinos PCINTx que queremos----
	clr temp ; Zera 'temp'
	ldi temp, (1<<PCINT21)|(1<<PCINT20) ; PCINT20 = PD4 e PCINT21 = PD5
	sts PCMSK2, temp ; Registrador onde contén PCINTx (16-23)

	clr temp ; Zera 'temp'
	ldi temp, (1<<PCINT11)|(1<<PCINT10) ; PCINT10 = PC2 e PCINT11 = PC3
	sts PCMSK1, temp  ; Registrador onde contén PCINTx (8-14)
	
	clr temp ; Zera 'temp'
	ldi temp, (1<<PCINT1)|(1<<PCINT0) ; PCINT0 = PB0 e PCINT1 = PB1
	sts PCMSK0, temp ; Registrador onde contén PCINTx (7-0)

	ser porthistory; Setando tudo para comparação (Usado na idf. dos PCINT)


	sei ; Ativa as interrupções globais

main:
	sei
	cpi sizeStack, 3
	brne main
	rjmp printAll
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

call_elevator:;botão de fora 
	ldi aux, 0
	
	cpi sizeStack, 0
	brne while
	push nextMove
	inc sizeStack
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
		cp aux, sizeStack; aqui não alteramos aux para 0, para continuar de onte parou o while anterior, tendo em vistas que os valores maiore que nextmove ja colocados
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


	rjmp main		
	


HANDLE_int0:
	ldi temp,67
	rcall print

	;ABRIR PORTA
	reti

HANDLE_int1:
	;FECHAR PORTA
	reti

;-----GUIDE-----
; PCMSK2 = PIND
; PCMSK1 = PINC
; PCMSK0 = PINB
;---------------

HANDLE_PCINT0: ; Vai Lidar com PORTD
	clr temp ; Zera 'temp'
	in temp, PIND ; Copia PIND
	eor temp,porthistory ; Como 'porthistory' é todo 1's o XOR retornará 0 em temp caso forem iguais
	in porthistory, PIND  ; Faz uma cópia de PIND para porthistory
	clr aux
	ldi aux,1<<PIND4
	and temp, aux ;  Se 'temp' for '1' PD4 foi ativo
	
	cpi temp, 0x1 ; Compara 'aux' com 1
	breq INTERRUPT_PIND4 ; Se igual, segue o branch
	INTERRUPT_PIND4:
	;IR PARA TERREO APERTO EXTERNO
	jmp end
	;IR PARA TERREO APERTO INTERNO
	end:
	reti

HANDLE_PCINT1: ; Vai Lidar com PORTC
	clr temp ; Zera 'temp'
	in temp, PINC ; Copia PINC
	eor temp,porthistory ; Como 'porthistory' é todo 1's o XOR retornará 0 em temp caso forem iguais
	in porthistory, PINC  ; Faz uma cópia de PINC para porthistory
	clr aux
	ldi aux,1<<PINC2
	and temp, aux ;  Se 'temp' for '1' PC2 foi ativo
	
	cpi temp, 0x1 ; Compara 'aux' com 1
	breq INTERRUPT_PINC2 ; Se igual, segue o branch
	INTERRUPT_PINC2:
	;IR PARA 1 ANDAR APERTO EXTERNO
	jmp end1
	;IR PARA 1 ANDAR APERTO INTERNO
	end1:
	reti

HANDLE_PCINT2: ; Vai Lidar com PORTB
	ldi temp,64
	rcall print
	clr temp ; Zera 'temp'
	in temp, PINB ; Copia PINB
	eor temp,porthistory ; Como 'porthistory' é todo 1's o XOR retornará 0 em temp caso forem iguais
	in porthistory, PINB  ; Faz uma cópia de PINB para porthistory
	clr aux
	ldi aux,1<<PINB1
	and temp, aux ;  Se 'temp' for '1' PB1 foi ativo
	
	cpi temp, 0x1 ; Compara 'aux' com 1
	breq INTERRUPT_PINB1 ; Se igual, segue o branch
	INTERRUPT_PINB1:
	cli
	ldi temp, 68
	rcall print
	ldi nextMove,0
	rjmp call_elevator ;
	;IR PARA 2 ANDAR APERTO EXTERNO
	jmp end2
	;IR PARA 2 ANDAR APERTO INTERNO
	end2:
	reti


