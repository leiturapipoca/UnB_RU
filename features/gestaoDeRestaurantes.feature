# language: pt

Funcionalidade:Gestão de Restaurantes e Catracas
    Como administrador, 
    eu quero cadastrar, editar e remover diferentes restaurantes e suas respectivas catracas físicas no sistema, 
    para que os funcionários possam selecioná-las na Aplicação de Controle.

    Cenario: Cadastrar restaurante e catraca
        Dado que o administrador acessa a tela de cadastro de restaurantes
        E que o administrador preenche os campos obrigatórios do restaurante
        E que o administrador preenche os campos obrigatórios da catraca física
        Quando o administrador clica no botão "Cadastrar"
        Então o sistema salva as informações do restaurante e da catraca física
        E exibe uma mensagem de sucesso
        E os funcionarios podem selecionar o restaurante e a catraca física na Aplicação de Controle

    Cenario: Editar restaurante e catraca
        Dado que o administrador acessa a tela de edição de restaurantes
        E que o administrador seleciona um restaurante existente
        E que o administrador altera os campos obrigatórios do restaurante
        E que o administrador altera os campos obrigatórios da catraca física
        Quando o administrador clica no botão "Salvar"
        Então o sistema atualiza as informações do restaurante e da catraca física
        E exibe uma mensagem de sucesso
        E os funcionarios podem selecionar o restaurante e a catraca física atualizados na Aplicação de Controle

    Cenario: Remover restaurante e catraca
        Dado que o administrador acessa a tela de remoção de restaurantes
        E que o administrador seleciona um restaurante existente
        Quando o administrador clica no botão "Remover"
        Então o sistema remove as informações do restaurante e da catraca física
        E exibe uma mensagem de sucesso
        E os funcionarios não podem mais selecionar o restaurante e a catraca física removidos na Aplicação de Controle

    