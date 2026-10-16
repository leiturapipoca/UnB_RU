# language: pt
Funcionalidade: Inscrição Única no FastPass
    Como estudante
    Quero me inscrever no sorteio gratuito do FastPass escolhendo apenas um time-frame por turno de refeição
    Para tentar garantir meu acesso sem filas

    Cenário: Inscrição bem sucedida
        Dado que o estudante ainda não possui inscrição para o turno "Almoço"
        Quando ele seleciona o time-frame "11:30 - 12:00" para "Almoço"
        E confirma a inscrição
        Então o status da inscrição deve ser "Aguardando sorteio"
    
    Cenário: Inscrição em dois time-frames
        Dado que o estudante já se inscreveu em um time-frame para o turno "Almoço"
        Quando o estudante tentar selecionar um novo time-frame
        Então nenhuma opção de time-frame deve estar disponível