# Wiki da Sprint 1

## Objetivos da Sprint
A sprint teve como foco o estudo e a documentação das histórias de usuário e a especificação de cenários BDD. Foi feito:
- Estudo e análise de Histórias de Usuário.
- Realização do Fork do repositório do projeto.
- Escrita das especificações em BDD das histórias de usuário usando Cucumber.
- Criação da Wiki.
- Criação de uma tag de *release* associada ao Pull Request de entrega.

## Histórias de Usuário:
**Issue #1** (Cadastro de Usuários): [`features/cadastro.feature`](https://github.com/neatzzy/UnB_RU/issues/1)
**Issue #2** (Recarga de Saldo): [`features/recargaSaldo.feature`](https://github.com/neatzzy/UnB_RU/issues/2)
**Issue #3** (Extrato e Histórico): [`features/extrato.feature`](https://github.com/neatzzy/UnB_RU/issues/3)
**Issue #4** (Autenticação do Funcionário): [`features/autenticacaoDoFuncionario.feature`](https://github.com/neatzzy/UnB_RU/issues/4)
**Issue #5** (Configuração de Ponto de Acesso): [`features/configuracaoDePontoDeAcesso.feature`](https://github.com/neatzzy/UnB_RU/issues/5)
**Issue #6** (Validação de Entrada): [`features/validacaoDeEntrada.feature`](https://github.com/neatzzy/UnB_RU/issues/6)
**Issue #7** (Histórico Local da Catracca): [`features/historicoLocalDaCatraca.feature`](https://github.com/neatzzy/UnB_RU/issues/7)
**Issue #8** (Gestão de Restaurantes e Catracas): [`features/gestaoDeRestaurantes.feature`](https://github.com/neatzzy/UnB_RU/issues/8)
**Issue #9** (Relatório Global de Acessos): [`features/relatorioGlobal.feature`](https://github.com/neatzzy/UnB_RU/issues/9)
**Issue #10** (Cardápio da Refeição atual): [`features/cardapio.feature`](https://github.com/neatzzy/UnB_RU/issues/10)
**Issue #11** (Exportação em PDF do Histórico do Estudante): [`features/historicoEstudante.feature`](https://github.com/neatzzy/UnB_RU/issues/11)
**Issue #12** (Exportação em PDF do Relatório de Operação): [`features/exportacaoEmPDF.feature`](https://github.com/neatzzy/UnB_RU/issues/12)
**Issue #14** (Inscrição Única no FastPass): [`features/inscricaoFastpass.feature`](https://github.com/neatzzy/UnB_RU/issues/14)
**Issue #15** (Notificação de Sorteio): [`features/notificacao.feature`](https://github.com/neatzzy/UnB_RU/issues/15)
**Issue #16** (Validação Rigorosa FastPass): [`features/validacaoRigorosa.feature`](https://github.com/neatzzy/UnB_RU/issues/16)
**Issue #17** (Gestão de Turnos e Time Frames): [`features/gestaoDeTurnos.feature`](https://github.com/neatzzy/UnB_RU/issues/17)


## Árvore do Projeto

```text
UnB_RU
 ┣ features/
 ┃ ┣ step_definitions/
 ┃ ┃ ┗ .gitkeep
 ┃ ┣ support/
 ┃ ┃ ┗ env.rb
 ┃ ┣ extrato.feature
 ┃ ┣ historicoEstudante.feature
 ┃ ┣ inscricaoFastpass.feature
 ┃ ┣ recargaSaldo.feature
 ┃ ┗ relatorioGlobal.feature
 ┣ scripts/
 ┃ ┗ create_users.rb
 ┣ cardapio.json
 ┣ README.MD
 ┗ wiki.md
