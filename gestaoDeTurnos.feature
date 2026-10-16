Funcionalidade: Gestão de Turnos e Time-frames (BÔNUS)
    Como gestor do restaurante
    Eu quero configurar os horários de funcionamento dos turnos
    Para controlar as janelas de acesso às refeições

    Cenário: Configuração de turno com sucesso
        Dado que o gestor está logado
        E informa horários válidos para o turno
        Quando ele clica em "Salvar Turno"
        Então o sistema deve salvar o novo horário
        E deve exibir a mensagem "Turno cadastrado com sucesso"

    Cenário: Acesso fora do horário do turno
        Dado que a catraca está fora da janela do turno ativo
        Quando o cliente tenta validar sua entrada
        Então a catraca deve permanecer bloqueada
        E deve exibir a mensagem "Fora do horário de atendimento"

    Cenário: Cadastro de turno com horários conflitantes
        Dado que o gestor está logado
        E informa um horário que coincide com outro turno existente
        Quando ele clica em "Salvar Turno"
        Então o sistema não deve salvar o turno
        E deve exibir a mensagem "Conflito de horário com turno existente"