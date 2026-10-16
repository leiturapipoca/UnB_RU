Funcionalidade: Notificação de Sorteio
    Como estudante, 
    Eu quero ser notificado se ganhei ou não o FastPass 1 hora antes do turno, 
    Para que eu possa planejar meu horário de ida ao RU.

   Contexto: 
	Dado que o usuário está cadastrado

    Cenário: O estudante recebe a notificação que ganhou
	Quando falta 1 hora para o time frame escolhido pelo estudante 
	Então ele recebe uma notificação de resultado do sorteio
	E vê "Você ganhou o sorteio"
	
    Cenário: O estudante recebeu a notificação de que não ganhou        
	Quando falta 1 hora para o time frame escolhido pelo estudante 
	Então ele recebe uma notificação de resultado do sorteio
	E vê "Você não ganhou o sorteio"

    Cenário: O estudante não recebeu uma notificação    
	Dado que o estudante bloqueou notificações     
	Quando falta 1 hora para o time frame escolhido pelo estudante 
	Então ele não recebe uma notificação com o resultado do sorteio
	   