# language: pt
Funcionalidade: Visualizar Extrato e Histórico 
    Como estudante
    Eu quero visualizar meu extrato de recargas e histórico de refeições
    Para ter controle sobre meus gastos e utilizações.


    Cenário: Visualização de extrato bem sucedida
        Dado que o estudante está logado
	E ele já fez uma recargar
        Quando ele tenta acessar a página "Extrato"
	Então ele deve ver o valor gasto no mês
	E ele deve ver o valor recarregado
	E ele deve ver a quantidade de refeições realizadas
        E ele deve ver o total gasto

    Cenário: Visualização de extrato sem movimentações 
        Dado que o estudante está logado
        E não possui recargas
	E não possui consumos
        Quando ele acessa a página "Extrato"
        Então ele deve ver a mensagem "Nenhuma movimentação encontrada"

    Cenário: Tentativa de acesso por um usuário não logado
        Dado que o estudante não está logado
        Quando ele tenta acessar a página "Extrato"
        Então ele deve ser redirecionado para a página de login
        E deve ver a mensagem "Faça login para visualizar seu extrato"