SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: intervalo_horario; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.intervalo_horario AS RANGE (
    subtype = time without time zone,
    multirange_type_name = public.intervalo_horario_multirange
);


--
-- Name: refeicao; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.refeicao AS character varying(13)
	CONSTRAINT refeicao_check CHECK (((VALUE)::text = ANY ((ARRAY['CAFE_DA_MANHA'::character varying, 'ALMOCO'::character varying, 'JANTAR'::character varying])::text[])));


--
-- Name: fn_acesso_debitar(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_acesso_debitar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.resultado = 'LIBERADO' AND NEW.valor_cobrado > 0 THEN
        UPDATE estudantes SET saldo = saldo - NEW.valor_cobrado
         WHERE id = NEW.estudante_id;
    END IF;
    RETURN NULL;
END $$;


--
-- Name: fn_acesso_imutavel(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_acesso_imutavel() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'Acesso é um registro imutável (%)', TG_OP;
END $$;


--
-- Name: fn_acesso_validar(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_acesso_validar() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
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
END $_$;


--
-- Name: fn_inscricao_janela_do_turno(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_inscricao_janela_do_turno() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sorteios s
                   JOIN janelas_fastpass j ON j.turno_id = s.turno_id
                   WHERE s.id = NEW.sorteio_id
                     AND j.id = NEW.janela_fastpass_id) THEN
        RAISE EXCEPTION 'A janela % não pertence ao turno do sorteio %',
                        NEW.janela_fastpass_id, NEW.sorteio_id;
    END IF;
    RETURN NEW;
END $$;


--
-- Name: fn_janela_dentro_do_turno(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_janela_dentro_do_turno() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM turnos t
                   WHERE t.id = NEW.turno_id
                     AND NEW.hora_inicio >= t.hora_inicio
                     AND NEW.hora_fim    <= t.hora_fim) THEN
        RAISE EXCEPTION 'Janela % - % fora do horário do turno %',
                        NEW.hora_inicio, NEW.hora_fim, NEW.turno_id;
    END IF;
    RETURN NEW;
END $$;


--
-- Name: fn_recarga_creditar(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_recarga_creditar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
END $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acessos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.acessos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sessao_operacao_id integer NOT NULL,
    turno_id integer,
    estudante_id integer,
    inscricao_fastpass_id integer,
    identificacao_lida character varying(64) NOT NULL,
    data_hora timestamp without time zone NOT NULL,
    modalidade character varying(8) NOT NULL,
    valor_cobrado numeric(10,2) DEFAULT 0 NOT NULL,
    resultado character varying(9) NOT NULL,
    motivo_bloqueio character varying(30),
    sincronizado_em timestamp without time zone,
    divergencia character varying(17),
    CONSTRAINT acessos_check CHECK (((((resultado)::text = 'LIBERADO'::text) AND (motivo_bloqueio IS NULL) AND (estudante_id IS NOT NULL) AND (turno_id IS NOT NULL)) OR (((resultado)::text = 'BLOQUEADO'::text) AND (motivo_bloqueio IS NOT NULL) AND (valor_cobrado = (0)::numeric)))),
    CONSTRAINT acessos_check1 CHECK ((((modalidade)::text = 'FASTPASS'::text) OR (inscricao_fastpass_id IS NULL))),
    CONSTRAINT acessos_check2 CHECK (((divergencia IS NULL) OR ((sincronizado_em IS NOT NULL) AND ((resultado)::text = 'LIBERADO'::text)))),
    CONSTRAINT acessos_check3 CHECK (((sincronizado_em IS NULL) OR (sincronizado_em >= data_hora))),
    CONSTRAINT acessos_divergencia_check CHECK (((divergencia)::text = ANY ((ARRAY['ENTRADA_DUPLICADA'::character varying, 'SALDO_NEGATIVO'::character varying])::text[]))),
    CONSTRAINT acessos_modalidade_check CHECK (((modalidade)::text = ANY ((ARRAY['COMUM'::character varying, 'FASTPASS'::character varying])::text[]))),
    CONSTRAINT acessos_motivo_bloqueio_check CHECK (((motivo_bloqueio)::text = ANY ((ARRAY['IDENTIFICACAO_INVALIDA'::character varying, 'SALDO_INSUFICIENTE'::character varying, 'ENTRADA_JA_REGISTRADA'::character varying, 'FORA_DO_TURNO'::character varying, 'FORA_DA_JANELA'::character varying, 'SEM_FASTPASS'::character varying, 'VALIDACAO_OFFLINE_INDISPONIVEL'::character varying])::text[]))),
    CONSTRAINT acessos_resultado_check CHECK (((resultado)::text = ANY ((ARRAY['LIBERADO'::character varying, 'BLOQUEADO'::character varying])::text[]))),
    CONSTRAINT acessos_valor_cobrado_check CHECK ((valor_cobrado >= (0)::numeric))
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: campi; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campi (
    id integer NOT NULL,
    nome character varying(80) NOT NULL
);


--
-- Name: campi_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.campi_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campi_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.campi_id_seq OWNED BY public.campi.id;


--
-- Name: cardapios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cardapios (
    id integer NOT NULL,
    turno_id integer NOT NULL,
    data date NOT NULL
);


--
-- Name: cardapios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cardapios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cardapios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cardapios_id_seq OWNED BY public.cardapios.id;


--
-- Name: catracas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catracas (
    id integer NOT NULL,
    restaurante_id integer NOT NULL,
    numero smallint NOT NULL,
    descricao character varying(80),
    modo_operacional character varying(20) DEFAULT 'COMUM'::character varying NOT NULL,
    status character varying(12) DEFAULT 'OFFLINE'::character varying NOT NULL,
    ultima_sincronizacao timestamp without time zone,
    CONSTRAINT catracas_modo_operacional_check CHECK (((modo_operacional)::text = ANY ((ARRAY['COMUM'::character varying, 'EXCLUSIVO_FASTPASS'::character varying])::text[]))),
    CONSTRAINT catracas_numero_check CHECK ((numero > 0)),
    CONSTRAINT catracas_status_check CHECK (((status)::text = ANY ((ARRAY['ONLINE'::character varying, 'OFFLINE'::character varying, 'PRONTA'::character varying, 'MANUTENCAO'::character varying, 'DESATIVADA'::character varying])::text[])))
);


--
-- Name: catracas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.catracas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: catracas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.catracas_id_seq OWNED BY public.catracas.id;


--
-- Name: estudantes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estudantes (
    id integer NOT NULL,
    matricula character(9) NOT NULL,
    nome character varying(120) NOT NULL,
    senha_hash character varying(255) NOT NULL,
    grupo_tarifario_id integer NOT NULL,
    grupo_valido_ate date,
    saldo numeric(10,2) DEFAULT 0 NOT NULL,
    notificacoes_ativas boolean DEFAULT true NOT NULL,
    fastpass_bloqueado_ate timestamp without time zone,
    CONSTRAINT estudantes_matricula_check CHECK ((matricula ~ '^[0-9]{9}$'::text))
);


--
-- Name: estudantes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.estudantes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estudantes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.estudantes_id_seq OWNED BY public.estudantes.id;


--
-- Name: funcionarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.funcionarios (
    id integer NOT NULL,
    siape character(7) NOT NULL,
    nome character varying(120) NOT NULL,
    senha_hash character varying(255) NOT NULL,
    perfil character varying(15) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    CONSTRAINT funcionarios_perfil_check CHECK (((perfil)::text = ANY ((ARRAY['OPERADOR'::character varying, 'GESTOR'::character varying, 'ADMINISTRADOR'::character varying])::text[]))),
    CONSTRAINT funcionarios_siape_check CHECK ((siape ~ '^[0-9]{7}$'::text))
);


--
-- Name: funcionarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.funcionarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: funcionarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.funcionarios_id_seq OWNED BY public.funcionarios.id;


--
-- Name: grupos_tarifarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grupos_tarifarios (
    id integer NOT NULL,
    nome character varying(20) NOT NULL,
    descricao character varying(200)
);


--
-- Name: grupos_tarifarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grupos_tarifarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grupos_tarifarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grupos_tarifarios_id_seq OWNED BY public.grupos_tarifarios.id;


--
-- Name: inscricoes_fastpass; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inscricoes_fastpass (
    id integer NOT NULL,
    sorteio_id integer NOT NULL,
    estudante_id integer NOT NULL,
    janela_fastpass_id integer NOT NULL,
    inscrito_em timestamp without time zone DEFAULT now() NOT NULL,
    status character varying(18) DEFAULT 'AGUARDANDO_SORTEIO'::character varying NOT NULL,
    codigo_passe character varying(20),
    notificado_em timestamp without time zone,
    CONSTRAINT inscricoes_fastpass_check CHECK (((codigo_passe IS NULL) OR ((status)::text = ANY ((ARRAY['CONTEMPLADO'::character varying, 'VAGA_LIBERADA'::character varying, 'UTILIZADA'::character varying, 'EXPIRADA'::character varying])::text[])))),
    CONSTRAINT inscricoes_fastpass_status_check CHECK (((status)::text = ANY ((ARRAY['AGUARDANDO_SORTEIO'::character varying, 'CONTEMPLADO'::character varying, 'NAO_CONTEMPLADO'::character varying, 'VAGA_LIBERADA'::character varying, 'UTILIZADA'::character varying, 'EXPIRADA'::character varying])::text[])))
);


--
-- Name: inscricoes_fastpass_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inscricoes_fastpass_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inscricoes_fastpass_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inscricoes_fastpass_id_seq OWNED BY public.inscricoes_fastpass.id;


--
-- Name: itens_cardapio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.itens_cardapio (
    id integer NOT NULL,
    cardapio_id integer NOT NULL,
    categoria character varying(16) NOT NULL,
    opcao character varying(20) DEFAULT 'GERAL'::character varying NOT NULL,
    descricao character varying(160) NOT NULL,
    ordem smallint DEFAULT 1 NOT NULL,
    CONSTRAINT itens_cardapio_categoria_check CHECK (((categoria)::text = ANY ((ARRAY['BEBIDA'::character varying, 'PANIFICACAO'::character varying, 'OPCAO_EXTRA'::character varying, 'GORDURA'::character varying, 'COMPLEMENTO'::character varying, 'FRUTA'::character varying, 'SALADA'::character varying, 'MOLHO_SALADA'::character varying, 'PRATO_PRINCIPAL'::character varying, 'GUARNICAO'::character varying, 'ACOMPANHAMENTO'::character varying, 'SOPA'::character varying, 'TORRADA'::character varying, 'SOBREMESA'::character varying])::text[]))),
    CONSTRAINT itens_cardapio_opcao_check CHECK (((opcao)::text = ANY ((ARRAY['GERAL'::character varying, 'PADRAO'::character varying, 'OVOLACTOVEGETARIANO'::character varying, 'VEGETARIANO_ESTRITO'::character varying])::text[])))
);


--
-- Name: itens_cardapio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.itens_cardapio_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: itens_cardapio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.itens_cardapio_id_seq OWNED BY public.itens_cardapio.id;


--
-- Name: janelas_fastpass; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.janelas_fastpass (
    id integer NOT NULL,
    turno_id integer NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fim time without time zone NOT NULL,
    cota_vagas smallint NOT NULL,
    ativa boolean DEFAULT true NOT NULL,
    CONSTRAINT janelas_fastpass_check CHECK ((hora_inicio < hora_fim)),
    CONSTRAINT janelas_fastpass_cota_vagas_check CHECK ((cota_vagas >= 0))
);


--
-- Name: janelas_fastpass_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.janelas_fastpass_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: janelas_fastpass_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.janelas_fastpass_id_seq OWNED BY public.janelas_fastpass.id;


--
-- Name: recargas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recargas (
    id integer NOT NULL,
    estudante_id integer NOT NULL,
    valor numeric(10,2) NOT NULL,
    metodo_pagamento character varying(15) NOT NULL,
    status character varying(10) DEFAULT 'PENDENTE'::character varying NOT NULL,
    codigo_transacao character varying(64),
    solicitada_em timestamp without time zone DEFAULT now() NOT NULL,
    expira_em timestamp without time zone,
    confirmada_em timestamp without time zone,
    CONSTRAINT recargas_check CHECK ((((status)::text = 'CONFIRMADA'::text) = (confirmada_em IS NOT NULL))),
    CONSTRAINT recargas_metodo_pagamento_check CHECK (((metodo_pagamento)::text = ANY ((ARRAY['PIX'::character varying, 'CARTAO_CREDITO'::character varying])::text[]))),
    CONSTRAINT recargas_status_check CHECK (((status)::text = ANY ((ARRAY['PENDENTE'::character varying, 'CONFIRMADA'::character varying, 'FALHOU'::character varying, 'EXPIRADA'::character varying])::text[]))),
    CONSTRAINT recargas_valor_check CHECK ((valor > (0)::numeric))
);


--
-- Name: recargas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recargas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recargas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recargas_id_seq OWNED BY public.recargas.id;


--
-- Name: restaurantes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurantes (
    id integer NOT NULL,
    campus_id integer NOT NULL,
    nome character varying(80) NOT NULL,
    piso smallint NOT NULL,
    capacidade_lugares integer,
    status character varying(15) DEFAULT 'EM_OPERACAO'::character varying NOT NULL,
    CONSTRAINT restaurantes_capacidade_lugares_check CHECK ((capacidade_lugares > 0)),
    CONSTRAINT restaurantes_piso_check CHECK ((piso >= 1)),
    CONSTRAINT restaurantes_status_check CHECK (((status)::text = ANY ((ARRAY['EM_OPERACAO'::character varying, 'INDISPONIVEL'::character varying, 'DESATIVADO'::character varying])::text[])))
);


--
-- Name: restaurantes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.restaurantes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: restaurantes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.restaurantes_id_seq OWNED BY public.restaurantes.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessoes_operacao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessoes_operacao (
    id integer NOT NULL,
    funcionario_id integer NOT NULL,
    catraca_id integer NOT NULL,
    iniciada_em timestamp without time zone DEFAULT now() NOT NULL,
    encerrada_em timestamp without time zone,
    CONSTRAINT sessoes_operacao_check CHECK (((encerrada_em IS NULL) OR (encerrada_em > iniciada_em)))
);


--
-- Name: sessoes_operacao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessoes_operacao_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessoes_operacao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessoes_operacao_id_seq OWNED BY public.sessoes_operacao.id;


--
-- Name: sorteios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sorteios (
    id integer NOT NULL,
    turno_id integer NOT NULL,
    data date NOT NULL,
    data_hora_resultado timestamp without time zone NOT NULL,
    status character varying(18) DEFAULT 'INSCRICOES_ABERTAS'::character varying NOT NULL,
    CONSTRAINT sorteios_status_check CHECK (((status)::text = ANY ((ARRAY['INSCRICOES_ABERTAS'::character varying, 'REALIZADO'::character varying, 'CANCELADO'::character varying])::text[])))
);


--
-- Name: sorteios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sorteios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sorteios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sorteios_id_seq OWNED BY public.sorteios.id;


--
-- Name: tarifas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tarifas (
    id integer NOT NULL,
    grupo_tarifario_id integer NOT NULL,
    tipo_refeicao public.refeicao NOT NULL,
    valor numeric(10,2) NOT NULL,
    CONSTRAINT tarifas_valor_check CHECK ((valor >= (0)::numeric))
);


--
-- Name: tarifas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tarifas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tarifas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tarifas_id_seq OWNED BY public.tarifas.id;


--
-- Name: turnos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.turnos (
    id integer NOT NULL,
    campus_id integer NOT NULL,
    tipo_refeicao public.refeicao NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fim time without time zone NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    fastpass_habilitado boolean DEFAULT false NOT NULL,
    tolerancia_atraso_min smallint DEFAULT 0 NOT NULL,
    antecedencia_min smallint DEFAULT 0 NOT NULL,
    trava_pontualidade boolean DEFAULT true NOT NULL,
    CONSTRAINT turnos_antecedencia_min_check CHECK ((antecedencia_min >= 0)),
    CONSTRAINT turnos_check CHECK ((hora_inicio < hora_fim)),
    CONSTRAINT turnos_tolerancia_atraso_min_check CHECK ((tolerancia_atraso_min >= 0))
);


--
-- Name: turnos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.turnos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: turnos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.turnos_id_seq OWNED BY public.turnos.id;


--
-- Name: vw_extrato; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_extrato AS
 SELECT r.estudante_id,
    r.confirmada_em AS data_hora,
    'RECARGA'::text AS tipo,
    (r.metodo_pagamento)::text AS descricao,
    r.valor
   FROM public.recargas r
  WHERE ((r.status)::text = 'CONFIRMADA'::text)
UNION ALL
 SELECT a.estudante_id,
    a.data_hora,
    'REFEICAO'::text AS tipo,
    (((((((t.tipo_refeicao)::text || ' — '::text) || (rs.nome)::text) || ' ('::text) || (cp.nome)::text) || '), catraca '::text) || c.numero) AS descricao,
    (- a.valor_cobrado) AS valor
   FROM (((((public.acessos a
     JOIN public.turnos t ON ((t.id = a.turno_id)))
     JOIN public.sessoes_operacao so ON ((so.id = a.sessao_operacao_id)))
     JOIN public.catracas c ON ((c.id = so.catraca_id)))
     JOIN public.restaurantes rs ON ((rs.id = c.restaurante_id)))
     JOIN public.campi cp ON ((cp.id = rs.campus_id)))
  WHERE ((a.resultado)::text = 'LIBERADO'::text);


--
-- Name: campi id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campi ALTER COLUMN id SET DEFAULT nextval('public.campi_id_seq'::regclass);


--
-- Name: cardapios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cardapios ALTER COLUMN id SET DEFAULT nextval('public.cardapios_id_seq'::regclass);


--
-- Name: catracas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catracas ALTER COLUMN id SET DEFAULT nextval('public.catracas_id_seq'::regclass);


--
-- Name: estudantes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudantes ALTER COLUMN id SET DEFAULT nextval('public.estudantes_id_seq'::regclass);


--
-- Name: funcionarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.funcionarios ALTER COLUMN id SET DEFAULT nextval('public.funcionarios_id_seq'::regclass);


--
-- Name: grupos_tarifarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grupos_tarifarios ALTER COLUMN id SET DEFAULT nextval('public.grupos_tarifarios_id_seq'::regclass);


--
-- Name: inscricoes_fastpass id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inscricoes_fastpass ALTER COLUMN id SET DEFAULT nextval('public.inscricoes_fastpass_id_seq'::regclass);


--
-- Name: itens_cardapio id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_cardapio ALTER COLUMN id SET DEFAULT nextval('public.itens_cardapio_id_seq'::regclass);


--
-- Name: janelas_fastpass id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.janelas_fastpass ALTER COLUMN id SET DEFAULT nextval('public.janelas_fastpass_id_seq'::regclass);


--
-- Name: recargas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recargas ALTER COLUMN id SET DEFAULT nextval('public.recargas_id_seq'::regclass);


--
-- Name: restaurantes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurantes ALTER COLUMN id SET DEFAULT nextval('public.restaurantes_id_seq'::regclass);


--
-- Name: sessoes_operacao id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessoes_operacao ALTER COLUMN id SET DEFAULT nextval('public.sessoes_operacao_id_seq'::regclass);


--
-- Name: sorteios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorteios ALTER COLUMN id SET DEFAULT nextval('public.sorteios_id_seq'::regclass);


--
-- Name: tarifas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarifas ALTER COLUMN id SET DEFAULT nextval('public.tarifas_id_seq'::regclass);


--
-- Name: turnos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.turnos ALTER COLUMN id SET DEFAULT nextval('public.turnos_id_seq'::regclass);


--
-- Name: acessos acessos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acessos
    ADD CONSTRAINT acessos_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: campi campi_nome_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campi
    ADD CONSTRAINT campi_nome_key UNIQUE (nome);


--
-- Name: campi campi_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campi
    ADD CONSTRAINT campi_pkey PRIMARY KEY (id);


--
-- Name: cardapios cardapios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cardapios
    ADD CONSTRAINT cardapios_pkey PRIMARY KEY (id);


--
-- Name: cardapios cardapios_turno_id_data_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cardapios
    ADD CONSTRAINT cardapios_turno_id_data_key UNIQUE (turno_id, data);


--
-- Name: catracas catracas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catracas
    ADD CONSTRAINT catracas_pkey PRIMARY KEY (id);


--
-- Name: catracas catracas_restaurante_id_numero_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catracas
    ADD CONSTRAINT catracas_restaurante_id_numero_key UNIQUE (restaurante_id, numero);


--
-- Name: estudantes estudantes_matricula_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudantes
    ADD CONSTRAINT estudantes_matricula_key UNIQUE (matricula);


--
-- Name: estudantes estudantes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudantes
    ADD CONSTRAINT estudantes_pkey PRIMARY KEY (id);


--
-- Name: funcionarios funcionarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.funcionarios
    ADD CONSTRAINT funcionarios_pkey PRIMARY KEY (id);


--
-- Name: funcionarios funcionarios_siape_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.funcionarios
    ADD CONSTRAINT funcionarios_siape_key UNIQUE (siape);


--
-- Name: grupos_tarifarios grupos_tarifarios_nome_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grupos_tarifarios
    ADD CONSTRAINT grupos_tarifarios_nome_key UNIQUE (nome);


--
-- Name: grupos_tarifarios grupos_tarifarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grupos_tarifarios
    ADD CONSTRAINT grupos_tarifarios_pkey PRIMARY KEY (id);


--
-- Name: inscricoes_fastpass inscricoes_fastpass_codigo_passe_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inscricoes_fastpass
    ADD CONSTRAINT inscricoes_fastpass_codigo_passe_key UNIQUE (codigo_passe);


--
-- Name: inscricoes_fastpass inscricoes_fastpass_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inscricoes_fastpass
    ADD CONSTRAINT inscricoes_fastpass_pkey PRIMARY KEY (id);


--
-- Name: inscricoes_fastpass inscricoes_fastpass_sorteio_id_estudante_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inscricoes_fastpass
    ADD CONSTRAINT inscricoes_fastpass_sorteio_id_estudante_id_key UNIQUE (sorteio_id, estudante_id);


--
-- Name: itens_cardapio itens_cardapio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_cardapio
    ADD CONSTRAINT itens_cardapio_pkey PRIMARY KEY (id);


--
-- Name: janelas_fastpass janelas_fastpass_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.janelas_fastpass
    ADD CONSTRAINT janelas_fastpass_pkey PRIMARY KEY (id);


--
-- Name: janelas_fastpass janelas_fastpass_turno_id_hora_inicio_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.janelas_fastpass
    ADD CONSTRAINT janelas_fastpass_turno_id_hora_inicio_key UNIQUE (turno_id, hora_inicio);


--
-- Name: janelas_fastpass janelas_fastpass_turno_id_intervalo_horario_excl; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.janelas_fastpass
    ADD CONSTRAINT janelas_fastpass_turno_id_intervalo_horario_excl EXCLUDE USING gist (turno_id WITH =, public.intervalo_horario(hora_inicio, hora_fim) WITH &&);


--
-- Name: recargas recargas_codigo_transacao_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recargas
    ADD CONSTRAINT recargas_codigo_transacao_key UNIQUE (codigo_transacao);


--
-- Name: recargas recargas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recargas
    ADD CONSTRAINT recargas_pkey PRIMARY KEY (id);


--
-- Name: restaurantes restaurantes_campus_id_nome_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurantes
    ADD CONSTRAINT restaurantes_campus_id_nome_key UNIQUE (campus_id, nome);


--
-- Name: restaurantes restaurantes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurantes
    ADD CONSTRAINT restaurantes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessoes_operacao sessoes_operacao_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessoes_operacao
    ADD CONSTRAINT sessoes_operacao_pkey PRIMARY KEY (id);


--
-- Name: sorteios sorteios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorteios
    ADD CONSTRAINT sorteios_pkey PRIMARY KEY (id);


--
-- Name: sorteios sorteios_turno_id_data_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorteios
    ADD CONSTRAINT sorteios_turno_id_data_key UNIQUE (turno_id, data);


--
-- Name: tarifas tarifas_grupo_tarifario_id_tipo_refeicao_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarifas
    ADD CONSTRAINT tarifas_grupo_tarifario_id_tipo_refeicao_key UNIQUE (grupo_tarifario_id, tipo_refeicao);


--
-- Name: tarifas tarifas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarifas
    ADD CONSTRAINT tarifas_pkey PRIMARY KEY (id);


--
-- Name: turnos turnos_campus_id_intervalo_horario_excl; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_campus_id_intervalo_horario_excl EXCLUDE USING gist (campus_id WITH =, public.intervalo_horario(hora_inicio, hora_fim) WITH &&);


--
-- Name: turnos turnos_campus_id_tipo_refeicao_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_campus_id_tipo_refeicao_key UNIQUE (campus_id, tipo_refeicao);


--
-- Name: turnos turnos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_pkey PRIMARY KEY (id);


--
-- Name: ix_acesso_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_acesso_data ON public.acessos USING btree (data_hora);


--
-- Name: ix_acesso_divergente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_acesso_divergente ON public.acessos USING btree (divergencia) WHERE (divergencia IS NOT NULL);


--
-- Name: ix_acesso_estudante; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_acesso_estudante ON public.acessos USING btree (estudante_id, data_hora);


--
-- Name: ix_acesso_sessao; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_acesso_sessao ON public.acessos USING btree (sessao_operacao_id);


--
-- Name: uq_acesso_unico_por_refeicao; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_acesso_unico_por_refeicao ON public.acessos USING btree (estudante_id, turno_id, ((data_hora)::date)) WHERE (((resultado)::text = 'LIBERADO'::text) AND (divergencia IS NULL));


--
-- Name: uq_sessao_aberta_catraca; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_sessao_aberta_catraca ON public.sessoes_operacao USING btree (catraca_id) WHERE (encerrada_em IS NULL);


--
-- Name: uq_sessao_aberta_operador; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_sessao_aberta_operador ON public.sessoes_operacao USING btree (funcionario_id) WHERE (encerrada_em IS NULL);


--
-- Name: acessos tg_acesso_debitar; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tg_acesso_debitar AFTER INSERT ON public.acessos FOR EACH ROW EXECUTE FUNCTION public.fn_acesso_debitar();


--
-- Name: acessos tg_acesso_imutavel; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tg_acesso_imutavel BEFORE DELETE OR UPDATE ON public.acessos FOR EACH ROW EXECUTE FUNCTION public.fn_acesso_imutavel();


--
-- Name: acessos tg_acesso_validar; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tg_acesso_validar BEFORE INSERT ON public.acessos FOR EACH ROW EXECUTE FUNCTION public.fn_acesso_validar();


--
-- Name: inscricoes_fastpass tg_inscricao_janela_do_turno; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tg_inscricao_janela_do_turno BEFORE INSERT OR UPDATE ON public.inscricoes_fastpass FOR EACH ROW EXECUTE FUNCTION public.fn_inscricao_janela_do_turno();


--
-- Name: janelas_fastpass tg_janela_dentro_do_turno; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tg_janela_dentro_do_turno BEFORE INSERT OR UPDATE ON public.janelas_fastpass FOR EACH ROW EXECUTE FUNCTION public.fn_janela_dentro_do_turno();


--
-- Name: recargas tg_recarga_creditar; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tg_recarga_creditar AFTER INSERT OR UPDATE ON public.recargas FOR EACH ROW EXECUTE FUNCTION public.fn_recarga_creditar();


--
-- Name: acessos acessos_estudante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acessos
    ADD CONSTRAINT acessos_estudante_id_fkey FOREIGN KEY (estudante_id) REFERENCES public.estudantes(id);


--
-- Name: acessos acessos_inscricao_fastpass_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acessos
    ADD CONSTRAINT acessos_inscricao_fastpass_id_fkey FOREIGN KEY (inscricao_fastpass_id) REFERENCES public.inscricoes_fastpass(id);


--
-- Name: acessos acessos_sessao_operacao_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acessos
    ADD CONSTRAINT acessos_sessao_operacao_id_fkey FOREIGN KEY (sessao_operacao_id) REFERENCES public.sessoes_operacao(id);


--
-- Name: acessos acessos_turno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acessos
    ADD CONSTRAINT acessos_turno_id_fkey FOREIGN KEY (turno_id) REFERENCES public.turnos(id);


--
-- Name: cardapios cardapios_turno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cardapios
    ADD CONSTRAINT cardapios_turno_id_fkey FOREIGN KEY (turno_id) REFERENCES public.turnos(id);


--
-- Name: catracas catracas_restaurante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catracas
    ADD CONSTRAINT catracas_restaurante_id_fkey FOREIGN KEY (restaurante_id) REFERENCES public.restaurantes(id);


--
-- Name: estudantes estudantes_grupo_tarifario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudantes
    ADD CONSTRAINT estudantes_grupo_tarifario_id_fkey FOREIGN KEY (grupo_tarifario_id) REFERENCES public.grupos_tarifarios(id);


--
-- Name: inscricoes_fastpass inscricoes_fastpass_estudante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inscricoes_fastpass
    ADD CONSTRAINT inscricoes_fastpass_estudante_id_fkey FOREIGN KEY (estudante_id) REFERENCES public.estudantes(id);


--
-- Name: inscricoes_fastpass inscricoes_fastpass_janela_fastpass_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inscricoes_fastpass
    ADD CONSTRAINT inscricoes_fastpass_janela_fastpass_id_fkey FOREIGN KEY (janela_fastpass_id) REFERENCES public.janelas_fastpass(id);


--
-- Name: inscricoes_fastpass inscricoes_fastpass_sorteio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inscricoes_fastpass
    ADD CONSTRAINT inscricoes_fastpass_sorteio_id_fkey FOREIGN KEY (sorteio_id) REFERENCES public.sorteios(id);


--
-- Name: itens_cardapio itens_cardapio_cardapio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_cardapio
    ADD CONSTRAINT itens_cardapio_cardapio_id_fkey FOREIGN KEY (cardapio_id) REFERENCES public.cardapios(id) ON DELETE CASCADE;


--
-- Name: janelas_fastpass janelas_fastpass_turno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.janelas_fastpass
    ADD CONSTRAINT janelas_fastpass_turno_id_fkey FOREIGN KEY (turno_id) REFERENCES public.turnos(id) ON DELETE CASCADE;


--
-- Name: recargas recargas_estudante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recargas
    ADD CONSTRAINT recargas_estudante_id_fkey FOREIGN KEY (estudante_id) REFERENCES public.estudantes(id);


--
-- Name: restaurantes restaurantes_campus_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurantes
    ADD CONSTRAINT restaurantes_campus_id_fkey FOREIGN KEY (campus_id) REFERENCES public.campi(id);


--
-- Name: sessoes_operacao sessoes_operacao_catraca_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessoes_operacao
    ADD CONSTRAINT sessoes_operacao_catraca_id_fkey FOREIGN KEY (catraca_id) REFERENCES public.catracas(id);


--
-- Name: sessoes_operacao sessoes_operacao_funcionario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessoes_operacao
    ADD CONSTRAINT sessoes_operacao_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES public.funcionarios(id);


--
-- Name: sorteios sorteios_turno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorteios
    ADD CONSTRAINT sorteios_turno_id_fkey FOREIGN KEY (turno_id) REFERENCES public.turnos(id);


--
-- Name: tarifas tarifas_grupo_tarifario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarifas
    ADD CONSTRAINT tarifas_grupo_tarifario_id_fkey FOREIGN KEY (grupo_tarifario_id) REFERENCES public.grupos_tarifarios(id);


--
-- Name: turnos turnos_campus_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_campus_id_fkey FOREIGN KEY (campus_id) REFERENCES public.campi(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261101031709');

