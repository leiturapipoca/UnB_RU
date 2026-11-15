# Wiki da Sprint 2: Autenticação, Restaurantes, Ponto de Acesso e FastPass

**Responsável:** Rafael Mileo Moreira Krauss Guimarães (matrícula 242024763, GitHub: `RafaelMkrauss`)

Esta página documenta as quatro features atribuídas ao Rafael (14 pontos de velocity, conforme a Wiki da Sprint 1).

| Issue | Feature | Pontos | Arquivo `.feature` | Cenários BDD | Situação |
|---|---|---|---|---|---|
| [#4](https://github.com/neatzzy/UnB_RU/issues/4) | Autenticação do Funcionário | 3 | `features/autenticacaoDoFuncionario.feature` | 2 | Implementada e testada |
| [#8](https://github.com/neatzzy/UnB_RU/issues/8) | Gestão de Restaurantes e Catracas | 3 | `features/gestaoDeRestaurantes.feature` | 3 | Implementada e testada |
| [#5](https://github.com/neatzzy/UnB_RU/issues/5) | Configuração de Ponto de Acesso | 3 | `features/configuracaoDePontoDeAcesso.feature` | 2 | Implementada e testada |
| [#16](https://github.com/neatzzy/UnB_RU/issues/16) | Validação Rigorosa FastPass (bônus) | 5 | `features/validacaoRigorosa.feature` | 2 | Implementada e testada |

**Resultado dos testes desta parte:** 9 de 9 cenários Cucumber passam (51 passos) e 78 exemplos RSpec passam.

## Fluxo geral

```text
Login do funcionário (#4)
        │
        ▼
Escolha do restaurante e da catraca (#5)   ← usa os restaurantes cadastrados pelo administrador (#8)
        │
        ▼
Painel de controle ──► Validação do passe FastPass na catraca (#16)
```

Usuários de teste (criados por `ruby bin/rails db:seed`, apenas fora de produção; senha `senha123`):

| Perfil | SIAPE | O que pode fazer |
|---|---|---|
| Administrador | `1000001` | Tudo, inclusive cadastrar restaurantes e catracas |
| Operador | `1000002` | Fazer login, escolher a catraca e validar entradas |

---

## #4 Autenticação do Funcionário

**História:** como funcionário do restaurante, quero fazer login na aplicação de controle para autenticar minha sessão e operar o sistema de forma segura.

**Como funciona**
1. O funcionário informa **SIAPE** e **senha** em `/login` e clica em **Entrar**.
2. Se estiverem corretos, a sessão é autenticada e ele vai para a escolha do restaurante. O cabeçalho "Aplicação de Controle" passa a aparecer com o nome dele e o botão **Sair**.
3. Se estiverem errados (ou o funcionário estiver inativo), aparece "SIAPE ou senha inválidos". A mensagem é a mesma para SIAPE inexistente e senha errada, para não revelar quais SIAPEs existem.

**Regras de negócio**
- A senha é guardada com **hash BCrypt**, nunca em texto puro (`Funcionario#senha=`).
- Só funcionários com `ativo = true` conseguem entrar.
- Ao entrar, a sessão anterior é descartada (`reset_session`), o que evita fixação de sessão.
- O login só é exigido nas páginas do funcionário (painel, restaurantes, ponto de acesso e FastPass). As páginas públicas (cadastro e extrato do estudante, cardápio, validação da catraca por matrícula) continuam abertas.

| Rota | Ação |
|---|---|
| `GET /login` | tela de login |
| `POST /login` | autentica |
| `DELETE /logout` | encerra a sessão (e a sessão de operação aberta) |

**Arquivos:** `app/controllers/sessoes_controller.rb`, `app/controllers/concerns/autenticacao.rb`, `app/models/funcionario.rb`, `app/views/sessoes/new.html.erb`, `app/controllers/painel_controller.rb`.
**Testes:** `features/step_definitions/autenticacao_steps.rb`, `spec/models/funcionario_spec.rb`, `spec/controllers/sessoes_controller_spec.rb`, `spec/controllers/painel_controller_spec.rb`.

---

## #8 Gestão de Restaurantes e Catracas

**História:** como administrador, quero cadastrar, editar e remover restaurantes e suas catracas físicas para que os funcionários possam selecioná-los na Aplicação de Controle.

**Como funciona**
- Em `/restaurantes` o administrador vê a lista e pode **cadastrar**, **editar** (**Salvar**) e **remover** (**Remover**).
- O restaurante e a catraca são cadastrados **no mesmo formulário** (`accepts_nested_attributes_for :catracas`).

**Regras de negócio**
- Somente o perfil **Administrador** acessa; o operador é redirecionado com a mensagem "Acesso restrito a administradores".
- Nome único por campus; piso maior ou igual a 1; número da catraca maior que 0 e único dentro do restaurante.
- Ao remover o restaurante, as catracas dele também são removidas.
- Se alguma catraca já tem **histórico de sessões de operação**, a remoção é recusada ("Não é possível remover: há sessões de operação registradas. Desative o restaurante."). Nesse caso o administrador muda o status do restaurante para *Desativado* ou *Indisponível*.

| Rota | Ação |
|---|---|
| `GET /restaurantes` | lista |
| `GET /restaurantes/new`, `POST /restaurantes` | cadastrar |
| `GET /restaurantes/:id/edit`, `PATCH /restaurantes/:id` | editar |
| `DELETE /restaurantes/:id` | remover |

**Arquivos:** `app/controllers/restaurantes_controller.rb`, `app/models/restaurante.rb`, `app/models/catraca.rb`, `app/helpers/restaurantes_helper.rb`, `app/views/restaurantes/`.
**Testes:** `features/step_definitions/gestao_restaurantes_steps.rb`, `spec/models/restaurante_spec.rb`, `spec/models/catraca_spec.rb`, `spec/controllers/restaurantes_controller_spec.rb`.

---

## #5 Configuração de Ponto de Acesso

**História:** como funcionário do restaurante, logo após o login, quero selecionar em qual restaurante vou gerenciar para que o sistema direcione as regras e grave os logs corretamente.

**Como funciona**
1. Depois do login, o funcionário vê a lista de restaurantes e catracas em `/ponto-de-acesso` e escolhe uma catraca.
2. O sistema cria uma **sessão de operação** (`SessaoOperacao`: funcionário + catraca + horário de início). Toda entrada registrada depois fica ligada a essa sessão, e por ela ao restaurante certo. É assim que os logs saem corretos.
3. O painel mostra o ponto de acesso escolhido e permite trocá-lo.

**Regras de negócio**
- Restaurante que não está **Em operação** é recusado ("O restaurante ... não está disponível"), e **nenhuma** sessão é gravada.
- Catraca em manutenção ou desativada também é recusada.
- O banco permite **uma sessão aberta por funcionário** e **uma por catraca**. Ao trocar de catraca, a sessão anterior é encerrada. Se a nova catraca estiver ocupada por outro funcionário, nada muda (operação "tudo ou nada", numa transação).
- Sem ponto de acesso escolhido, o painel redireciona de volta para a seleção.

| Rota | Ação |
|---|---|
| `GET /ponto-de-acesso` | lista |
| `POST /ponto-de-acesso` | confirma a escolha |

**Arquivos:** `app/controllers/ponto_acesso_controller.rb`, `app/models/sessao_operacao.rb`, `app/views/ponto_acesso/new.html.erb`.
**Testes:** `features/step_definitions/ponto_acesso_steps.rb`, `spec/models/sessao_operacao_spec.rb`, `spec/controllers/ponto_acesso_controller_spec.rb`.

---

## #16 Validação Rigorosa FastPass (bônus)

**História:** como aplicação de controle, quero checar se o aluno sorteado para o FastPass chegou no horário vigente. Se sim, comando a liberação da catraca física e debito o saldo; se não, bloqueio a entrada.

**Como funciona**
1. O operador digita o **código do passe** em `/catraca/fastpass`.
2. O serviço `ValidadorFastpass` procura a inscrição **contemplada** com aquele código.
3. Verifica a data do sorteio e se o horário atual está dentro do horário vigente.
4. Dentro do horário: registra o acesso como **liberado**, marca o passe como **utilizado** e comanda a liberação da catraca. O **saldo é debitado pelo banco de dados** (gatilhos `fn_acesso_validar` e `fn_acesso_debitar`), valor conforme a tarifa do grupo do aluno e a refeição.
5. Fora do horário: registra o acesso como **bloqueado**, com o motivo, e **nada é cobrado**.

**Regra de horário vigente adotada:** a janela do FastPass do aluno (`hora_inicio` a `hora_fim`), com `antecedencia_min` de antecedência e `tolerancia_atraso_min` de tolerância de atraso, ambos configurados no turno. Se o turno tem `trava_pontualidade = false`, o horário não bloqueia.

**Motivos de bloqueio registrados:** `sem_fastpass` (código inexistente), `fora_do_turno` (passe de outro dia), `fora_da_janela` (atrasado ou adiantado), `saldo_insuficiente`, `entrada_ja_registrada`.

**Observações**
- A integração com a catraca física é simulada: o comando de liberar/bloquear é registrado no log da aplicação (`comandar_catraca`), um ponto único para ligar o hardware depois.
- O fuso horário da aplicação é Brasília (`config.time_zone`), e as colunas de hora do turno são lidas como hora do dia.

| Rota | Ação |
|---|---|
| `GET /catraca/fastpass` | tela de leitura do passe |
| `POST /catraca/fastpass` | valida o passe |

**Arquivos:** `app/services/validador_fastpass.rb`, `app/controllers/fastpass_controller.rb`, `app/views/fastpass/new.html.erb`.
**Testes:** `features/step_definitions/validacao_rigorosa_steps.rb`, `spec/services/validador_fastpass_spec.rb`, `spec/controllers/fastpass_controller_spec.rb`.

---

## Como executar o projeto e os testes

```text
bundle install
ruby bin/rails db:create db:migrate db:seed
ruby bin/rails server          # http://localhost:3000  (entrar com SIAPE 1000001 / senha123)
```

Testes (no Windows em português, defina antes `CUCUMBER_OUTPUT_ENCODING=UTF-8`):

```text
bundle exec rspec
bundle exec cucumber features/autenticacaoDoFuncionario.feature features/gestaoDeRestaurantes.feature features/configuracaoDePontoDeAcesso.feature features/validacaoRigorosa.feature
```

## Testes desta parte

| Tipo | Arquivos | Exemplos |
|---|---|---|
| Cucumber (BDD) | 4 `.feature` e 4 arquivos de steps | 9 cenários |
| RSpec modelos | `funcionario`, `restaurante`, `catraca`, `sessao_operacao` | 29 |
| RSpec controllers | `sessoes`, `painel`, `restaurantes`, `ponto_acesso`, `fastpass` | 45 |
| RSpec serviço | `validador_fastpass` | 4 |

## Pontos de atenção e próximos passos

- A validação de entrada comum (`/catraca/validacao`, feature #6) usa a primeira sessão de operação aberta no banco. O ideal é usar a sessão do funcionário logado (`sessao_operacao_atual`), para que o restaurante registrado seja sempre o escolhido no ponto de acesso.
- O login do estudante ainda depende do atalho de testes `/test_login/:id`; falta uma tela de login própria para estudantes.
