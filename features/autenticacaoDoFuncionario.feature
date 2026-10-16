# language: pt

Funcionalidade:Autenticação do Funcionário
    Como funcionário do restaurante, 
    eu quero fazer login na aplicação de controle, 
    para autenticar minha sessão 
    e operar o sistema de forma segura

    Cenario: Login bem-sucedido
        Dado que o funcionário acessa a tela de login
        E que o funcionário insere credenciais válidas
        Quando o funcionário clica no botão "Entrar"
        Então o sistema autentica a sessão do funcionário
        E exibe a tela principal da aplicação de controle para o funcionário operar o sistema de forma segura

    Cenario: Login mal-sucedido
        Dado que o funcionário acessa a tela de login
        E que o funcionário insere credenciais inválidas
        Quando o funcionário clica no botão "Entrar"
        Então o sistema não autentica a sessão do funcionário
        E exibe uma mensagem de erro para o funcionário
    
    