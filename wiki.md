# Wiki da Sprint 1

## Equipe
**Product Owner:** Filipe Nobre Nunes - Matrícula: 242023523
**Scrum Master:**  Guilherme Silva Cavalcante - Matrícula: 242001508
**Desenvolvedor:** Artur Nunes de Souza - Matrícula: 241002485
**Desenvolvedor:** Rafael Mileo Moreira Krauss Guimaraes - Matrícula: 242024763


## Objetivos da Sprint
A sprint teve como foco o estudo e a documentação das histórias de usuário e a especificação de cenários BDD. Foi feito:
- Estudo e análise de Histórias de Usuário.
- Realização do Fork do repositório do projeto.
- Escrita das especificações em BDD das histórias de usuário usando Cucumber.
- Criação da Wiki.
- Criação de uma tag de release associada ao pull request de entrega.


## Padrões do Projeto
Como essa ainda é a etapa inicial do projeto, decidimos não delegar um conjunto de features relacionadas para nenhum membro específico. Dado a simplicidade da tarefa, decidimos adotar o método trunk based development para o versionamento. O padrões utilizados foram:
### Fluxo de Branches
Nenhuma feature foi desenvolvida e as regras de negócio serão abordadas mais a fundo quando desenvolvermos os TDD's. O foco 
principal dessa sprint foi a criação dos BDD's. Criamos uma branch para cada conjunto de features novo a partir da main. Ao 
finalizar o desenvolvimento daquele conjunto, abrimos um pull request. Após o merge na main, a branch da feature é deletada 
para manter o repositório limpo.

### Padrão de Commits
Utilização de prefixos para clareza dos commits: 
    feat: para novas funcionalidades.
    fix: para correção de bugs.
    init: para iniciar o repositório.

### Padrão de Revisão de Código
**Revisão Geral:** Decidimos dar pelo menos uma feature de cada escopo do projeto para cada participante. Desse modo, para a criação de um BDD de uma feature que está envolvida com múltiplas histórias de usuário, o membro deveria checar os BDD's dos outros para garantir coesão, sendo esse o método de revisão para a etapa inicial.


## Funcionalidades, Regras de Negócio e Velocity
**Velocity planejado:** 58 pontos.

### Atribuições - Guilherme (Total: 10 Pontos)
**#1 Cadastro de Usuários (3 pts)**
**#3 Extrato e Histórico (2 pts)**
**#10 Cardápio da Refeição atual (2 pts)**
**#15 Notificação de Sorteio (3 pts)**

### Atribuições - Filipe (Total: 18 Pontos)
**#2 Recarga de Saldo (5 pts)**
**#9 Relatório Global de Acessos (5 pts)**
**#11 Exportação em PDF do Histórico do Estudante (3 pts)**
**#14 Inscrição Única no FastPass (5 pts)**

### Atribuições - Artur (Total: 16 Pontos)
**#6 Validação de Entrada (5 pts)**
**#7 Histórico Local da Catraca (3 pts)**
**#12 Exportação em PDF do Relatório de Operação (3 pts)**
**#17 Gestão de Turnos e Time Frames (5 pts)**

### Atribuições - Rafael (Total: 14 Pontos)
**#4 Autenticação do Funcionário (3 pts)**
**#5 Configuração de Ponto de Acesso (3 pts)**
**#8 Gestão de Restaurantes e Catracas (3 pts)**
**#16 Validação Rigorosa FastPass (5 pts)**


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
 ┃ ┣ autenticacaoDoFuncionario.feature
 ┃ ┣ cadastro.feature
 ┃ ┣ cardapio.feature
 ┃ ┣ configuracaoDePontoDeAcesso.feature
 ┃ ┣ exportacaoEmPDF.feature
 ┃ ┣ extrato.feature
 ┃ ┣ gestaoDeRestaurantes.feature
 ┃ ┣ gestaoDeTurnos.feature
 ┃ ┣ historicoEstudante.feature
 ┃ ┣ historicoLocalDaCatraca.feature
 ┃ ┣ inscricaoFastpass.feature
 ┃ ┣ notificacao.feature
 ┃ ┣ recargaSaldo.feature
 ┃ ┣ relatorioGlobal.feature
 ┃ ┣ validacaoDeEntrada.feature
 ┃ ┗ validacaoRigorosa.feature
 ┣ scripts/
 ┃ ┗ create_users.rb
 ┣ cardapio.json
 ┣ README.MD
 ┗ wiki.md