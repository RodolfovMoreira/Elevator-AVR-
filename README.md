*Projetos em Assembly.*

* O presente repositório tem como finalidade o projeto de um elevador, Projetos exigidos na disciplina de Microcontroladores.


*Pré-requisitos e especificações do projeto de elevadores:*

Linguagem:  Assembly;
Compilador: 
Arduino: 328p 
IDE: AtmelStudio
SO: windows :cry

1. Prioriza os andares mais altos caso tenha duas chamadas;

Exemplo: Se estiver no térreo subindo para o 2º andar, não deve parar no 1º andar, mesmo que o botão que fica no primeiro andar tenha sido pressionado antes de o carro do elevador passar pelo 1° andar. Obs: Essa prioridade não acontece para os botões dentro do elevador.

2. Se a porta do elevador ficar aberta por 5 segundos, toca-se o Buzzer;
3. Se a porta do elevador ficar aberta por 10 segundos, deve ser fechada;
4. O elevador leva 3 segundos de um andar para o outro;
5. Enviar log pela serial;

   5.1. Elevador parado no andar X com porta aberta/fechada; 

   5.2. Elevador passando no andar X indo para o andar Y; 

   5.3 Botões apertados dentro do elevador: x,y,z;

   5.4  Botões apertados nos andares: x, y, z.

*Arduino*

Estrutura

Os requisitos com relação a estrutura são:

* Ter um Térreo mais 3 andares;
* Ter botões dentro da cabine do elevador para mover o elevador;
* Um botão dentro do elevador para abrir e fechar a porta;
* Ter botões que correspondem as chamada do elevador em cada andar;
* Utilizar um display de 7 segmentos para indicar o andar atual;
* Utilizar um LED para indicar o estado da porta(aberto ou fechado)
* Utilizar um LCD para mostrar o log do sistema

*Equipamentos*

Cada andar:
* 1x Display 7 segmentos para mostrar onde está o elevador;
* 1x Botão para chamar elevador.

Dentro do elevador:
* 1x Display 7 segmentos para mostrar onde está o elevador;
* 3x botões para definir para qual andar ir;
* 1x botão para abrir a porta;
* 1x botão para fechar a porta;
* 1x Buzzer para avisar que a porta esta aberta; 
* 1x Led verde para indicar abertura da porta.
