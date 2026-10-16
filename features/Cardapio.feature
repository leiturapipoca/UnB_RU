Funcionalidade: Cardápio da refeição atual 
    Como estudante
    Eu quero poder ver o cardápio da refeição que esteja sendo servida agora. Incluindo as opções padrão, ovolactovegetariano e
    vegetariano estrito.
    Para decidir qual eu vou comer

	
    Cenário: O estudante consegue ver o cardápio 
	Quando o estudante tenta visualizar o cardápio
	Então ele visualiza o cardápio da refeição atual
	E vê a opção padrão, ovolacovegetariana e vegetariana estrito 

    Cenário: O estudante tenta visualizar o cardápio fora do horário de funcionamento
        Dado que o RU não está no horário de funcionamento
	Quando o estudante tenta acessar o cardápio
	Então ele vê "Nenhuma refeição está sendo servida no momento"

    