# language: pt

Funcionalidade: Configuração de Ponto de Acesso
    Como funcionário do restaurante, 
    logo após o login, 
    eu quero selecionar em qual restaurante vou gerenciar, 
    para que o sistema direcione as regras corretamente 
    e grave os logs corretamente.

    Cenario: Selecionar restaurante
        Dado que o funcionário acessa a tela de seleção de restaurante
        E que o funcionário visualiza a lista de restaurantes disponíveis
        Quando o funcionário seleciona um restaurante da lista
        Então o sistema direciona as regras corretamente para o restaurante selecionado
        E grava os logs corretamente para o restaurante selecionado

    Cenario: Restaurante não disponível
        Dado que o funcionário acessa a tela de seleção de restaurante
        E que o funcionário visualiza a lista de restaurantes disponíveis
        Quando o funcionário tenta selecionar um restaurante que não está disponível
        Então o sistema exibe uma mensagem de erro informando que o restaurante não está disponível
        E não direciona as regras para o restaurante selecionado
        E não grava os logs para o restaurante selecionado