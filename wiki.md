# Wiki da Sprint 1

## Objetivos da Sprint
A sprint teve como foco o estudo e a documentação das histórias de usuário e a especificação de cenários BDD. Foi feito:
- Estudo e análise de Histórias de Usuário.
- Realização do Fork do repositório do projeto.
- Escrita das especificações em BDD das histórias de usuário usando Cucumber.
- Criação da Wiki.
- Criação de uma tag de *release* associada ao Pull Request de entrega.

## Histórias de Usuário:
**Issue #2** (Recarga de Saldo): [`features/recargaSaldo.feature`](https://github.com/neatzzy/UnB_RU/issues/2)
**Issue #3** (Extrato e Histórico): [`features/extrato.feature`](https://github.com/neatzzy/UnB_RU/issues/3)
**Issue #9** (Relatório Global de Acessos): [`features/relatorioGlobal.feature`](https://github.com/neatzzy/UnB_RU/issues/9)
**Issue #11** (Exportação em PDF do Histórico do Estudante): [`features/historicoEstudante.feature`](https://github.com/neatzzy/UnB_RU/issues/11)
**Issue #14** (Inscrição Única no FastPass): [`features/inscricaoFastpass.feature`](https://github.com/neatzzy/UnB_RU/issues/14)


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