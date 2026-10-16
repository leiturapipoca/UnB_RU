# language: pt
Funcionalidade: Relatório Global de Acessos
    Como administrador
    Eu quero visualizar o histórico completo de todos os acessos do campus, podendo filtrar e agrupar os dados por restaurante e por catraca específica
    Para ter uma visão gerencial de toda a operação    

    Cenário: Relatório gerado com sucesso
        Dado que o administrador está logado
        E acessa a página de "Relatório Global de Acessos"
        E existem registros de acesso no restaurante "1"
        Quando o administrador seleciona o filtro de restaurante para "1"
        E seleciona o filtro de catraca para "Catraca 1"
        Então o resultado deve exibir apenas os estudantes que passaram pela "Catraca 1" do restaurante "1"

    Cenário: Filtros sem resultados
        Dado que o administrador está logado no sistema
        E acessa a página de "Relatório Global de Acessos"
        E a "Catraca 1" do restaurante "4" não teve acessos
        Quando o administrador seleciona o restaurante "4"
        E filtra pela "Catraca 1"
        Então a tabela de resultados deve aparecer vazia
        E uma mensagem deve informar "Nenhum acesso corresponde à busca"