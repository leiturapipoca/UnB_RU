Funcionalidade: Exportação em PDF do Relatório de Operação
    Como gestor do restaurante
    Eu quero exportar o relatório de histórico em PDF
    Para arquivar e compartilhar os dados da operação

    Cenário: Exportação de relatório bem-sucedida
        Dado que o gestor está logado
        E seleciona um período com movimentações
        Quando ele clica em "Exportar PDF"
        Então o sistema deve gerar o arquivo PDF do relatório
        E deve iniciar o download do arquivo

    Cenário: Exportação de período sem dados
        Dado que o gestor está logado
        E seleciona um período sem registros
        Quando ele clica em "Exportar PDF"
        Então o sistema não deve gerar o PDF
        E deve exibir a mensagem "Nenhum registro encontrado para o período"

    Cenário: Tentativa de exportação por usuário não autorizado
        Dado que o usuário logado não é gestor
        Quando ele tenta acessar a página de relatórios
        Então ele deve ser redirecionado para a página inicial
        E deve ver a mensagem "Acesso restrito a gestores"