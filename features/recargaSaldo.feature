# language: pt
Funcionalidade: Recarga de Saldo
    Como estudante
    Eu quero adicionar créditos à minha conta via PIX ou cartão de crédito
    Para que eu tenha saldo suficiente para acessar os restaurantes

    Cenário: Recarga bem sucedida
        Dado que o estudante possui "10" reais de saldo na conta
        Quando o estudante selecionar pagamento via "PIX"
        E selecionar "67" reais
        E o pagamento for recebido
        Então o saldo da conta deve mudar para "77" reais
    
    Cenário: Pagamento não efetuado
        Dado que o estudante possui "10" reais de saldo na conta
        Quando o estudante selecionar pagamento via "PIX"
        E o pagamento não for efetivado dentro do prazo
        Então uma mensagem deve informar "Erro ao efetivar pagamento"
        E o saldo da conta deve permanecer "10" reais