Funcionalidade: Histórico Local da Catraca
    Como operador do sistema
    Eu quero que a catraca armazene os acessos localmente
    Para garantir a operação contínua mesmo sem conexão com a rede

    Cenário: Registro de acesso offline
        Dado que a catraca está sem conexão de rede
        Quando um acesso válido é realizado
        Então a catraca deve liberar a entrada
        E deve salvar o evento no histórico local

    Cenário: Sincronização automática dos dados
        Dado que a catraca possui registros salvos localmente
        Quando a conexão de rede é reestabelecida
        Então o sistema deve enviar o histórico local para o servidor central
        E deve limpar os registros pendentes da memória local

    Cenário: Leitura local em falha total de validação
        Dado que a catraca está offline
        E a identificação não pode ser verificada localmente
        Quando a leitura é realizada
        Então a catraca deve permanecer bloqueada
        E deve exibir a mensagem "Validação indisponível offline"