# language: pt
Funcionalidade: Exportação em PDF do Histórico do Estudante
    Como estudante
    Eu quero poder exportar meu Extrato e Histórico de Refeições como PDF
    Para poder controlar melhor as minhas finanças

    Cenário: Exportação bem-sucedida
        Dado que o estudante acessa a página de "Histórico de Refeições"
        E possui registros de refeições no mês atual
        Quando ele clica no botão "Exportar"
        E seleciona o formato "PDF"
        Então o sistema deve fazer o download de um arquivo chamado "extrato_refeicoes.pdf"
    
    Cenário: Tentativa de exportação de um histórico sem registros
        Dado que o estudante acessou o histórico sem nenhuma refeição registrada
        Quando ele clica no botão "Exportar"
        Então o sistema deve bloquar a geração do arquivo