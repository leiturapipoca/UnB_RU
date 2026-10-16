Funcionalidade: Cadastro de Usuário 
    Como estudante
    Eu quero me cadastrar no sistema utilizando minha matrícula, 
    Para que eu possa criar minha conta de acesso ao RU.

    Contexto:
    	Dado que o estudante está na tela de "Cadastro"	

    Cenário: Cadastro bem sucedido
        Dado que o estudante forneceu sua matrícula, seu nome e sua senha
	Quando ele tenta criar o cadastro
	Então ele vê "Usuário cadastrado com sucesso"
	E sua conta do RU é criada 

    Cenário: Tentativa de cadastro com campos vazios
        Dado que o estudante não preencheu nenhum campo
	Quando ele tenta criar o cadastro
	Então ele vê "Preencha todos os campos"

    Cenário: Tentativa de cadastro com matrícula inválida
	Dado que o estudante forneceu uma matrícula inválida
	Quando ele tenta criar o cadastro
	Então ele vê as regras de preenchimento
    
    Cenário: Tentativa de cadastro com matrícula já registrada
   	Dado que o estudante forneceu uma matrícula já registrada
	Quando ele tenta criar o cadastro
	Então ele vê "Estudante já cadastrado"