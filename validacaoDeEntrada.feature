Funcionalidade: Validação de Entrada (MVP)
    Como funcionário do restaurante,
    eu quero que o sistema valide a entrada dos clientes na catraca,
    para liberar o acesso apenas a pessoas autorizadas
    e registrar a entrada no sistema

    Cenário: Liberação de entrada bem-sucedida
        Dado que o cliente está com a identificação válida
        Quando ele passa a identificação na catraca
        Então a catraca deve ser liberada
        E o sistema deve registrar a entrada

    Cenário: Bloqueio de entrada por identificação inválida
        Dado que o cliente possui uma identificação inválida ou sem saldo
        Quando ele tenta passar a identificação na catraca
        Então a catraca deve permanecer bloqueada
        E deve exibir a mensagem "Acesso Não Autorizado"

    Cenário: Tentativa de reuso imediato do mesmo bilhete
        Dado que o cliente já validou sua entrada na refeição atual
        Quando ele tenta passar a mesma identificação novamente
        Então a catraca deve permanecer bloqueada
        E deve exibir a mensagem "Entrada já registrada"