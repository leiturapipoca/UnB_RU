# language: pt

Funcionalidade:Validação Rigorosa FastPass
    Como aplicação de controle, 
    eu quero checar se o aluno sorteado para o Fastpass chegou no horário vigente. 
    Se sim, comando a liberação da catraca física e debito o saldo; 
    se não, bloqueio a entrada.

    Cenario: Aluno chega no horário
        Dado que o aluno foi sorteado para o Fastpass
        E que o aluno chega no horário vigente
        Quando o sistema verifica a chegada do aluno
        Então o sistema libera a catraca física
        E debita o saldo do aluno

    Cenario: Aluno chega atrasado
        Dado que o aluno foi sorteado para o Fastpass
        E que o aluno chega atrasado
        Quando o sistema verifica a chegada do aluno
        Então o sistema bloqueia a entrada do aluno

