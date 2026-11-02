# db/migrate/20261101xxxxxx_create_estrutura_inicial_ru.rb
class CreateEstruturaInicialRu < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      -- =====================================================================
      --  UnB RU — Modelo Relacional Padronizado para Rails (PostgreSQL 14+)
      -- =====================================================================

      CREATE EXTENSION IF NOT EXISTS btree_gist;

      CREATE TYPE intervalo_horario AS RANGE (subtype = time);

      CREATE DOMAIN refeicao AS VARCHAR(13)
          CHECK (VALUE IN ('CAFE_DA_MANHA', 'ALMOCO', 'JANTAR'));

      -- ---------------------------------------------------------------------
      --  Estrutura física: campi (= RU), restaurantes e catracas
      -- ---------------------------------------------------------------------
      CREATE TABLE campi (
          id             SERIAL       PRIMARY KEY,
          nome           VARCHAR(80)  NOT NULL UNIQUE
      );

      CREATE TABLE restaurantes (
          id                  SERIAL        PRIMARY KEY,
          campus_id           INT           NOT NULL REFERENCES campi(id),
          nome                VARCHAR(80)   NOT NULL,
          piso                SMALLINT      NOT NULL CHECK (piso >= 1),
          capacidade_lugares  INT           CHECK (capacidade_lugares > 0),
          status              VARCHAR(15)   NOT NULL DEFAULT 'EM_OPERACAO'
                              CHECK (status IN ('EM_OPERACAO', 'INDISPONIVEL', 'DESATIVADO')),
          UNIQUE (campus_id, nome)
      );

      CREATE TABLE catracas (
          id                    SERIAL       PRIMARY KEY,
          restaurante_id        INT          NOT NULL REFERENCES restaurantes(id),
          numero                SMALLINT     NOT NULL CHECK (numero > 0),
          descricao             VARCHAR(80),
          modo_operacional      VARCHAR(20)  NOT NULL DEFAULT 'COMUM'
                                CHECK (modo_operacional IN ('COMUM', 'EXCLUSIVO_FASTPASS')),
          status                VARCHAR(12)  NOT NULL DEFAULT 'OFFLINE'
                                CHECK (status IN ('ONLINE', 'OFFLINE', 'PRONTA', 'MANUTENCAO', 'DESATIVADA')),
          ultima_sincronizacao  TIMESTAMP,
          UNIQUE (restaurante_id, numero)
      );

      -- ---------------------------------------------------------------------
      --  Tarifa: preço por grupo de usuário e refeição
      -- ---------------------------------------------------------------------
      CREATE TABLE grupos_tarifarios (
          id         SERIAL        PRIMARY KEY,
          nome       VARCHAR(20)   NOT NULL UNIQUE,
          descricao  VARCHAR(200)
      );

      CREATE TABLE tarifas (
          id                  SERIAL         PRIMARY KEY,
          grupo_tarifario_id  INT            NOT NULL REFERENCES grupos_tarifarios(id),
          tipo_refeicao       refeicao       NOT NULL,
          valor               NUMERIC(10,2)  NOT NULL CHECK (valor >= 0),
          UNIQUE (grupo_tarifario_id, tipo_refeicao)
      );

      -- ---------------------------------------------------------------------
      --  Pessoas (estudantes e funcionários)
      -- ---------------------------------------------------------------------
      CREATE TABLE estudantes (
          id                      SERIAL         PRIMARY KEY,
          matricula               CHAR(9)        NOT NULL UNIQUE CHECK (matricula ~ '^[0-9]{9}$'),
          nome                    VARCHAR(120)   NOT NULL,
          senha_hash              VARCHAR(255)   NOT NULL,
          grupo_tarifario_id      INT            NOT NULL REFERENCES grupos_tarifarios(id),
          grupo_valido_ate        DATE,
          saldo                   NUMERIC(10,2)  NOT NULL DEFAULT 0,
          notificacoes_ativas     BOOLEAN        NOT NULL DEFAULT TRUE,
          fastpass_bloqueado_ate  TIMESTAMP
      );

      CREATE TABLE funcionarios (
          id          SERIAL        PRIMARY KEY,
          siape       CHAR(7)       NOT NULL UNIQUE CHECK (siape ~ '^[0-9]{7}$'),
          nome        VARCHAR(120)  NOT NULL,
          senha_hash  VARCHAR(255)  NOT NULL,
          perfil      VARCHAR(15)   NOT NULL
                      CHECK (perfil IN ('OPERADOR', 'GESTOR', 'ADMINISTRADOR')),
          ativo       BOOLEAN       NOT NULL DEFAULT TRUE
      );

      -- ---------------------------------------------------------------------
      --  Carteira (recargas)
      -- ---------------------------------------------------------------------
      CREATE TABLE recargas (
          id                SERIAL         PRIMARY KEY,
          estudante_id      INT            NOT NULL REFERENCES estudantes(id),
          valor             NUMERIC(10,2)  NOT NULL CHECK (valor > 0),
          metodo_pagamento  VARCHAR(15)    NOT NULL CHECK (metodo_pagamento IN ('PIX', 'CARTAO_CREDITO')),
          status            VARCHAR(10)    NOT NULL DEFAULT 'PENDENTE'
                            CHECK (status IN ('PENDENTE', 'CONFIRMADA', 'FALHOU', 'EXPIRADA')),
          codigo_transacao  VARCHAR(64)    UNIQUE,
          solicitada_em     TIMESTAMP      NOT NULL DEFAULT now(),
          expira_em         TIMESTAMP,
          confirmada_em     TIMESTAMP,
          CHECK ((status = 'CONFIRMADA') = (confirmada_em IS NOT NULL))
      );

      -- ---------------------------------------------------------------------
      --  Turnos, time-frames e cardápio do RU
      -- ---------------------------------------------------------------------
      CREATE TABLE turnos (
          id                     SERIAL     PRIMARY KEY,
          campus_id              INT        NOT NULL REFERENCES campi(id),
          tipo_refeicao          refeicao   NOT NULL,
          hora_inicio            TIME       NOT NULL,
          hora_fim               TIME       NOT NULL,
          ativo                  BOOLEAN    NOT NULL DEFAULT TRUE,
          fastpass_habilitado    BOOLEAN    NOT NULL DEFAULT FALSE,
          tolerancia_atraso_min  SMALLINT   NOT NULL DEFAULT 0 CHECK (tolerancia_atraso_min >= 0),
          antecedencia_min       SMALLINT   NOT NULL DEFAULT 0 CHECK (antecedencia_min >= 0),
          trava_pontualidade     BOOLEAN    NOT NULL DEFAULT TRUE,
          CHECK (hora_inicio < hora_fim),
          UNIQUE (campus_id, tipo_refeicao),
          EXCLUDE USING gist (
              campus_id WITH =,
              intervalo_horario(hora_inicio, hora_fim) WITH &&
          )
      );

      CREATE TABLE janelas_fastpass (
          id           SERIAL    PRIMARY KEY,
          turno_id     INT       NOT NULL REFERENCES turnos(id) ON DELETE CASCADE,
          hora_inicio  TIME      NOT NULL,
          hora_fim     TIME      NOT NULL,
          cota_vagas   SMALLINT  NOT NULL CHECK (cota_vagas >= 0),
          ativa        BOOLEAN   NOT NULL DEFAULT TRUE,
          CHECK (hora_inicio < hora_fim),
          UNIQUE (turno_id, hora_inicio),
          EXCLUDE USING gist (
              turno_id WITH =,
              intervalo_horario(hora_inicio, hora_fim) WITH &&
          )
      );

      CREATE TABLE cardapios (
          id        SERIAL  PRIMARY KEY,
          turno_id  INT     NOT NULL REFERENCES turnos(id),
          data      DATE    NOT NULL,
          UNIQUE (turno_id, data)
      );

      CREATE TABLE itens_cardapio (
          id           SERIAL        PRIMARY KEY,
          cardapio_id  INT           NOT NULL REFERENCES cardapios(id) ON DELETE CASCADE,
          categoria    VARCHAR(16)   NOT NULL CHECK (categoria IN (
                           'BEBIDA', 'PANIFICACAO', 'OPCAO_EXTRA', 'GORDURA', 'COMPLEMENTO', 'FRUTA',
                           'SALADA', 'MOLHO_SALADA', 'PRATO_PRINCIPAL', 'GUARNICAO',
                           'ACOMPANHAMENTO', 'SOPA', 'TORRADA', 'SOBREMESA')),
          opcao        VARCHAR(20)   NOT NULL DEFAULT 'GERAL' CHECK (opcao IN (
                           'GERAL', 'PADRAO', 'OVOLACTOVEGETARIANO', 'VEGETARIANO_ESTRITO')),
          descricao    VARCHAR(160)  NOT NULL,
          ordem        SMALLINT      NOT NULL DEFAULT 1
      );

      -- ---------------------------------------------------------------------
      --  FastPass (sorteios e inscrições)
      -- ---------------------------------------------------------------------
      CREATE TABLE sorteios (
          id                   SERIAL       PRIMARY KEY,
          turno_id             INT          NOT NULL REFERENCES turnos(id),
          data                 DATE         NOT NULL,
          data_hora_resultado  TIMESTAMP    NOT NULL,
          status               VARCHAR(18)  NOT NULL DEFAULT 'INSCRICOES_ABERTAS'
                               CHECK (status IN ('INSCRICOES_ABERTAS', 'REALIZADO', 'CANCELADO')),
          UNIQUE (turno_id, data)
      );

      CREATE TABLE inscricoes_fastpass (
          id                  SERIAL       PRIMARY KEY,
          sorteio_id          INT          NOT NULL REFERENCES sorteios(id),
          estudante_id        INT          NOT NULL REFERENCES estudantes(id),
          janela_fastpass_id  INT          NOT NULL REFERENCES janelas_fastpass(id),
          inscrito_em         TIMESTAMP    NOT NULL DEFAULT now(),
          status              VARCHAR(18)  NOT NULL DEFAULT 'AGUARDANDO_SORTEIO'
                              CHECK (status IN ('AGUARDANDO_SORTEIO', 'CONTEMPLADO', 'NAO_CONTEMPLADO',
                                                'VAGA_LIBERADA', 'UTILIZADA', 'EXPIRADA')),
          codigo_passe        VARCHAR(20)  UNIQUE,
          notificado_em       TIMESTAMP,
          UNIQUE (sorteio_id, estudante_id),
          CHECK (codigo_passe IS NULL OR status IN ('CONTEMPLADO', 'VAGA_LIBERADA', 'UTILIZADA', 'EXPIRADA'))
      );

      -- ---------------------------------------------------------------------
      --  Operação das catracas (sessões e acessos)
      -- ---------------------------------------------------------------------
      CREATE TABLE sessoes_operacao (
          id              SERIAL     PRIMARY KEY,
          funcionario_id  INT        NOT NULL REFERENCES funcionarios(id),
          catraca_id      INT        NOT NULL REFERENCES catracas(id),
          iniciada_em     TIMESTAMP  NOT NULL DEFAULT now(),
          encerrada_em    TIMESTAMP,
          CHECK (encerrada_em IS NULL OR encerrada_em > iniciada_em)
      );

      CREATE UNIQUE INDEX uq_sessao_aberta_catraca  ON sessoes_operacao (catraca_id)     WHERE encerrada_em IS NULL;
      CREATE UNIQUE INDEX uq_sessao_aberta_operador ON sessoes_operacao (funcionario_id) WHERE encerrada_em IS NULL;

      CREATE TABLE acessos (
          id                     UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
          sessao_operacao_id     INT            NOT NULL REFERENCES sessoes_operacao(id),
          turno_id               INT            REFERENCES turnos(id),
          estudante_id           INT            REFERENCES estudantes(id),
          inscricao_fastpass_id  INT            REFERENCES inscricoes_fastpass(id),
          identificacao_lida     VARCHAR(64)    NOT NULL,
          data_hora              TIMESTAMP      NOT NULL,
          modalidade             VARCHAR(8)     NOT NULL CHECK (modalidade IN ('COMUM', 'FASTPASS')),
          valor_cobrado          NUMERIC(10,2)  NOT NULL DEFAULT 0 CHECK (valor_cobrado >= 0),
          resultado              VARCHAR(9)     NOT NULL CHECK (resultado IN ('LIBERADO', 'BLOQUEADO')),
          motivo_bloqueio        VARCHAR(30)    CHECK (motivo_bloqueio IN (
                                     'IDENTIFICACAO_INVALIDA', 'SALDO_INSUFICIENTE', 'ENTRADA_JA_REGISTRADA',
                                     'FORA_DO_TURNO', 'FORA_DA_JANELA', 'SEM_FASTPASS',
                                     'VALIDACAO_OFFLINE_INDISPONIVEL')),
          sincronizado_em        TIMESTAMP,
          divergencia            VARCHAR(17)    CHECK (divergencia IN ('ENTRADA_DUPLICADA', 'SALDO_NEGATIVO')),
          CHECK ( (resultado = 'LIBERADO'  AND motivo_bloqueio IS NULL
                   AND estudante_id IS NOT NULL AND turno_id IS NOT NULL)
               OR (resultado = 'BLOQUEADO' AND motivo_bloqueio IS NOT NULL AND valor_cobrado = 0) ),
          CHECK (modalidade = 'FASTPASS' OR inscricao_fastpass_id IS NULL),
          CHECK (divergencia IS NULL OR (sincronizado_em IS NOT NULL AND resultado = 'LIBERADO')),
          CHECK (sincronizado_em IS NULL OR sincronizado_em >= data_hora)
      );

      CREATE UNIQUE INDEX uq_acesso_unico_por_refeicao
          ON acessos (estudante_id, turno_id, (data_hora::date))
          WHERE resultado = 'LIBERADO' AND divergencia IS NULL;
      CREATE INDEX ix_acesso_data       ON acessos (data_hora);
      CREATE INDEX ix_acesso_sessao     ON acessos (sessao_operacao_id);
      CREATE INDEX ix_acesso_estudante  ON acessos (estudante_id, data_hora);
      CREATE INDEX ix_acesso_divergente ON acessos (divergencia) WHERE divergencia IS NOT NULL;

      -- ---------------------------------------------------------------------
      --  Funções e Gatilhos (Triggers)
      -- ---------------------------------------------------------------------

      -- RI-1: a janela FastPass precisa caber dentro do horário do turno
      CREATE FUNCTION fn_janela_dentro_do_turno() RETURNS trigger AS $$
      BEGIN
          IF NOT EXISTS (SELECT 1 FROM turnos t
                         WHERE t.id = NEW.turno_id
                           AND NEW.hora_inicio >= t.hora_inicio
                           AND NEW.hora_fim    <= t.hora_fim) THEN
              RAISE EXCEPTION 'Janela % - % fora do horário do turno %',
                              NEW.hora_inicio, NEW.hora_fim, NEW.turno_id;
          END IF;
          RETURN NEW;
      END $$ LANGUAGE plpgsql;

      CREATE TRIGGER tg_janela_dentro_do_turno
          BEFORE INSERT OR UPDATE ON janelas_fastpass
          FOR EACH ROW EXECUTE FUNCTION fn_janela_dentro_do_turno();

      -- RI-2: a janela escolhida na inscrição tem de ser do mesmo turno do sorteio
      CREATE FUNCTION fn_inscricao_janela_do_turno() RETURNS trigger AS $$
      BEGIN
          IF NOT EXISTS (SELECT 1 FROM sorteios s
                         JOIN janelas_fastpass j ON j.turno_id = s.turno_id
                         WHERE s.id = NEW.sorteio_id
                           AND j.id = NEW.janela_fastpass_id) THEN
              RAISE EXCEPTION 'A janela % não pertence ao turno do sorteio %',
                              NEW.janela_fastpass_id, NEW.sorteio_id;
          END IF;
          RETURN NEW;
      END $$ LANGUAGE plpgsql;

      CREATE TRIGGER tg_inscricao_janela_do_turno
          BEFORE INSERT OR UPDATE ON inscricoes_fastpass
          FOR EACH ROW EXECUTE FUNCTION fn_inscricao_janela_do_turno();

      -- RI-3: validação de cada acesso liberado
      CREATE FUNCTION fn_acesso_validar() RETURNS trigger AS $$
      DECLARE
          v_tipo   refeicao;
          v_campus INT;
          v_grupo  INT;
          v_saldo  NUMERIC(10,2);
      BEGIN
          IF NEW.turno_id IS NOT NULL THEN
              SELECT t.tipo_refeicao, t.campus_id INTO v_tipo, v_campus
                FROM turnos t WHERE t.id = NEW.turno_id;
              IF NOT EXISTS (SELECT 1 FROM sessoes_operacao s
                               JOIN catracas c     ON c.id = s.catraca_id
                               JOIN restaurantes r ON r.id = c.restaurante_id
                              WHERE s.id = NEW.sessao_operacao_id AND r.campus_id = v_campus) THEN
                  RAISE EXCEPTION 'O turno % não é do campus da catraca da sessão %',
                                  NEW.turno_id, NEW.sessao_operacao_id;
              END IF;
          END IF;

          IF NEW.resultado <> 'LIBERADO' OR NEW.estudante_id IS NULL OR NEW.turno_id IS NULL THEN
              RETURN NEW;
          END IF;

          SELECT e.grupo_tarifario_id, e.saldo INTO v_grupo, v_saldo
            FROM estudantes e WHERE e.id = NEW.estudante_id
             FOR UPDATE;

          SELECT tf.valor INTO NEW.valor_cobrado
            FROM tarifas tf WHERE tf.grupo_tarifario_id = v_grupo AND tf.tipo_refeicao = v_tipo;
          IF NOT FOUND THEN
              RAISE EXCEPTION 'Sem tarifa para o grupo % na refeição %', v_grupo, v_tipo;
          END IF;

          IF EXISTS (SELECT 1 FROM acessos a JOIN turnos t ON t.id = a.turno_id
                      WHERE a.estudante_id = NEW.estudante_id
                        AND a.resultado = 'LIBERADO' AND a.divergencia IS NULL
                        AND t.tipo_refeicao = v_tipo
                        AND a.data_hora::date = NEW.data_hora::date) THEN
              IF NEW.sincronizado_em IS NULL THEN
                  RAISE EXCEPTION 'Entrada já registrada: estudante % já fez a refeição % em %',
                                  NEW.estudante_id, v_tipo, NEW.data_hora::date;
              END IF;
              NEW.divergencia := 'ENTRADA_DUPLICADA';
          ELSIF v_saldo < NEW.valor_cobrado THEN
              IF NEW.sincronizado_em IS NULL THEN
                  RAISE EXCEPTION 'Saldo insuficiente: estudante % tem R$ %, a refeição custa R$ %',
                                  NEW.estudante_id, v_saldo, NEW.valor_cobrado;
              END IF;
              NEW.divergencia := 'SALDO_NEGATIVO';
          END IF;
          RETURN NEW;
      END $$ LANGUAGE plpgsql;

      CREATE TRIGGER tg_acesso_validar
          BEFORE INSERT ON acessos
          FOR EACH ROW EXECUTE FUNCTION fn_acesso_validar();

      -- RI-4: débito no acesso liberado
      CREATE FUNCTION fn_acesso_debitar() RETURNS trigger AS $$
      BEGIN
          IF NEW.resultado = 'LIBERADO' AND NEW.valor_cobrado > 0 THEN
              UPDATE estudantes SET saldo = saldo - NEW.valor_cobrado
               WHERE id = NEW.estudante_id;
          END IF;
          RETURN NULL;
      END $$ LANGUAGE plpgsql;

      CREATE TRIGGER tg_acesso_debitar
          AFTER INSERT ON acessos
          FOR EACH ROW EXECUTE FUNCTION fn_acesso_debitar();

      -- Crédito quando a recarga é confirmada
      CREATE FUNCTION fn_recarga_creditar() RETURNS trigger AS $$
      BEGIN
          IF TG_OP = 'UPDATE' AND OLD.status = 'CONFIRMADA'
             AND (NEW.status <> 'CONFIRMADA' OR NEW.valor <> OLD.valor
                  OR NEW.estudante_id <> OLD.estudante_id) THEN
              RAISE EXCEPTION 'Recarga % já confirmada não pode ser alterada', OLD.id;
          END IF;
          IF NEW.status = 'CONFIRMADA' AND (TG_OP = 'INSERT' OR OLD.status <> 'CONFIRMADA') THEN
              UPDATE estudantes SET saldo = saldo + NEW.valor
               WHERE id = NEW.estudante_id;
          END IF;
          RETURN NULL;
      END $$ LANGUAGE plpgsql;

      CREATE TRIGGER tg_recarga_creditar
          AFTER INSERT OR UPDATE ON recargas
          FOR EACH ROW EXECUTE FUNCTION fn_recarga_creditar();

      -- RI-5: imutabilidade de acesso
      CREATE FUNCTION fn_acesso_imutavel() RETURNS trigger AS $$
      BEGIN
          RAISE EXCEPTION 'Acesso é um registro imutável (%)', TG_OP;
      END $$ LANGUAGE plpgsql;

      CREATE TRIGGER tg_acesso_imutavel
          BEFORE UPDATE OR DELETE ON acessos
          FOR EACH ROW EXECUTE FUNCTION fn_acesso_imutavel();

      -- ---------------------------------------------------------------------
      --  View de Extrato do Estudante
      -- ---------------------------------------------------------------------
      CREATE VIEW vw_extrato AS
          SELECT r.estudante_id,
                 r.confirmada_em          AS data_hora,
                 'RECARGA'                AS tipo,
                 r.metodo_pagamento::text AS descricao,
                 r.valor                  AS valor
            FROM recargas r
           WHERE r.status = 'CONFIRMADA'
      UNION ALL
          SELECT a.estudante_id,
                 a.data_hora,
                 'REFEICAO',
                 t.tipo_refeicao || ' — ' || rs.nome || ' (' || cp.nome || '), catraca ' || c.numero,
                 -a.valor_cobrado
            FROM acessos a
            JOIN turnos t            ON t.id  = a.turno_id
            JOIN sessoes_operacao so ON so.id = a.sessao_operacao_id
            JOIN catracas c          ON c.id  = so.catraca_id
            JOIN restaurantes rs     ON rs.id = c.restaurante_id
            JOIN campi cp            ON cp.id = rs.campus_id
           WHERE a.resultado = 'LIBERADO';
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS vw_extrato;
      DROP TABLE IF EXISTS acessos CASCADE;
      DROP TABLE IF EXISTS sessoes_operacao CASCADE;
      DROP TABLE IF EXISTS inscricoes_fastpass CASCADE;
      DROP TABLE IF EXISTS sorteios CASCADE;
      DROP TABLE IF EXISTS itens_cardapio CASCADE;
      DROP TABLE IF EXISTS cardapios CASCADE;
      DROP TABLE IF EXISTS janelas_fastpass CASCADE;
      DROP TABLE IF EXISTS turnos CASCADE;
      DROP TABLE IF EXISTS recargas CASCADE;
      DROP TABLE IF EXISTS funcionarios CASCADE;
      DROP TABLE IF EXISTS estudantes CASCADE;
      DROP TABLE IF EXISTS tarifas CASCADE;
      DROP TABLE IF EXISTS grupos_tarifarios CASCADE;
      DROP TABLE IF EXISTS catracas CASCADE;
      DROP TABLE IF EXISTS restaurantes CASCADE;
      DROP TABLE IF EXISTS campi CASCADE;
      DROP FUNCTION IF EXISTS fn_janela_dentro_do_turno() CASCADE;
      DROP FUNCTION IF EXISTS fn_inscricao_janela_do_turno() CASCADE;
      DROP FUNCTION IF EXISTS fn_acesso_validar() CASCADE;
      DROP FUNCTION IF EXISTS fn_acesso_debitar() CASCADE;
      DROP FUNCTION IF EXISTS fn_recarga_creditar() CASCADE;
      DROP FUNCTION IF EXISTS fn_acesso_imutavel() CASCADE;
      DROP DOMAIN IF EXISTS refeicao CASCADE;
      DROP TYPE IF EXISTS intervalo_horario CASCADE;
    SQL
  end
end