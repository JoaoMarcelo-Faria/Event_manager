-- =====================================================
-- EXTENSÃO (necessária para a constraint de conflito de espaço)
-- =====================================================
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- =====================================================
-- ENUMs
-- =====================================================
CREATE TYPE tipo_promotor AS ENUM ('PESSOA_FISICA', 'ORGANIZACAO');

CREATE TYPE tipo_atividade AS ENUM (
    'PALESTRA', 'WORKSHOP', 'MINICURSO', 'PAINEL',
    'MESA_REDONDA', 'APRESENTACAO', 'OUTRO'
);

CREATE TYPE papel_participante AS ENUM (
    'PARTICIPANTE', 'PALESTRANTE', 'INSTRUTOR', 'ORGANIZADOR'
);

CREATE TYPE status_inscricao AS ENUM ( 
    'EM ESPERA', 'CANCELADA', 'CONFIRMADA'
);

-- =====================================================
-- PROMOTOR (supertipo) E ESPECIALIZAÇÃO D (total e disjunta)
-- =====================================================
CREATE TABLE promotor(
    id_promotor   INTEGER GENERATED ALWAYS AS IDENTITY,
    nome          VARCHAR(50)  NOT NULL,
    email_contato VARCHAR(50)  NOT NULL,
    tipo          tipo_promotor NOT NULL,
    CONSTRAINT pk_promotor PRIMARY KEY (id_promotor),
    CONSTRAINT uq_promotor_id_tipo UNIQUE (id_promotor, tipo),
    CONSTRAINT ck_promotor_email
        CHECK (email_contato ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

CREATE TABLE pessoa_fisica(
    cpf         VARCHAR(11)   NOT NULL,
    id_promotor INTEGER       NOT NULL,
    tipo        tipo_promotor NOT NULL DEFAULT 'PESSOA_FISICA',
    CONSTRAINT pk_pessoa_fisica PRIMARY KEY (cpf),
    CONSTRAINT uq_pessoa_fisica_promotor UNIQUE (id_promotor),
    CONSTRAINT fk_pessoa_fisica_promotor
        FOREIGN KEY (id_promotor, tipo)
        REFERENCES promotor (id_promotor, tipo)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT ck_pessoa_fisica_tipo CHECK (tipo = 'PESSOA_FISICA'),
    CONSTRAINT ck_pessoa_fisica_cpf  CHECK (cpf ~ '^[0-9]{11}$')
);

CREATE TABLE organizacao(
    cnpj        VARCHAR(14)   NOT NULL,
    id_promotor INTEGER       NOT NULL,
    tipo        tipo_promotor NOT NULL DEFAULT 'ORGANIZACAO',
    CONSTRAINT pk_organizacao PRIMARY KEY (cnpj),
    CONSTRAINT uq_organizacao_promotor UNIQUE (id_promotor),
    CONSTRAINT fk_organizacao_promotor
        FOREIGN KEY (id_promotor, tipo)
        REFERENCES promotor (id_promotor, tipo)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT ck_organizacao_tipo CHECK (tipo = 'ORGANIZACAO'),
    CONSTRAINT ck_organizacao_cnpj CHECK (cnpj ~ '^[0-9]{14}$')
);

-- Participação total: todo promotor precisa estar em UMA das subtabelas.
-- Verificada só no fim da transação (DEFERRED).
CREATE FUNCTION fn_checa_especializacao_promotor() RETURNS trigger AS $$
DECLARE
    v_id INTEGER;
BEGIN
    v_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.id_promotor ELSE NEW.id_promotor END;

    IF EXISTS (SELECT 1 FROM promotor WHERE id_promotor = v_id)
       AND NOT EXISTS (SELECT 1 FROM pessoa_fisica WHERE id_promotor = v_id)
       AND NOT EXISTS (SELECT 1 FROM organizacao   WHERE id_promotor = v_id) THEN
        RAISE EXCEPTION 'Promotor % precisa ser pessoa fisica ou organizacao', v_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_promotor_total
    AFTER INSERT ON promotor
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_checa_especializacao_promotor();

CREATE CONSTRAINT TRIGGER trg_pessoa_fisica_total
    AFTER DELETE ON pessoa_fisica
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_checa_especializacao_promotor();

CREATE CONSTRAINT TRIGGER trg_organizacao_total
    AFTER DELETE ON organizacao
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_checa_especializacao_promotor();

-- =====================================================
-- EVENTO
-- =====================================================
CREATE TABLE evento(
    id_evento   INTEGER GENERATED ALWAYS AS IDENTITY,
    id_promotor INTEGER      NOT NULL,
    titulo      VARCHAR(100) NOT NULL,
    datai       DATE,
    datat       DATE,
    edicao      INT,
    CONSTRAINT pk_evento PRIMARY KEY (id_evento),
    CONSTRAINT uq_evento_titulo_edicao UNIQUE (titulo, edicao),
    CONSTRAINT fk_evento_promotor
        FOREIGN KEY (id_promotor) REFERENCES promotor (id_promotor)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_evento_periodo CHECK (datat >= datai)
);

-- =====================================================
-- ATIVIDADE
-- =====================================================
CREATE TABLE atividade(
    id_atividade  INTEGER GENERATED ALWAYS AS IDENTITY,
    id_evento     INTEGER        NOT NULL,
    titulo        VARCHAR(100)   NOT NULL,
    tipo          tipo_atividade NOT NULL,
    descricao     TEXT,
    exige_inscri  BOOLEAN        NOT NULL,
    CONSTRAINT pk_atividade PRIMARY KEY (id_atividade),
    CONSTRAINT fk_atividade_evento
        FOREIGN KEY (id_evento) REFERENCES evento (id_evento)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- =====================================================
-- ESPACO E RECURSO
-- =====================================================
CREATE TABLE espaco(
    id_espaco  INTEGER GENERATED ALWAYS AS IDENTITY,
    nome       VARCHAR(50) NOT NULL,
    capacidade INTEGER     NOT NULL,
    CONSTRAINT pk_espaco PRIMARY KEY (id_espaco),
    CONSTRAINT ck_espaco_capacidade CHECK (capacidade > 0)
);

CREATE TABLE recurso(
    id_recurso INTEGER GENERATED ALWAYS AS IDENTITY,
    nome       VARCHAR(50) NOT NULL,
    descricao  TEXT,
    CONSTRAINT pk_recurso PRIMARY KEY (id_recurso)
);

-- =====================================================
-- PARTICIPANTE
-- =====================================================
CREATE TABLE participante(
    id_particip INTEGER GENERATED ALWAYS AS IDENTITY,
    nome        VARCHAR(100) NOT NULL,
    documento   VARCHAR(20)  NOT NULL,
    email       VARCHAR(100) NOT NULL,
    CONSTRAINT pk_participante PRIMARY KEY (id_particip),
    CONSTRAINT uq_participante_documento UNIQUE (documento),
    CONSTRAINT ck_participante_email
        CHECK (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

-- =====================================================
-- SESSAO
-- (data e horários podem ser NULL: sessão ainda em planejamento)
-- =====================================================
CREATE TABLE sessao(
    id_sessao    INTEGER GENERATED ALWAYS AS IDENTITY,
    id_atividade INTEGER NOT NULL,
    id_espaco    INTEGER NOT NULL,
    data         DATE,
    horarioi     TIME,
    horariot     TIME,
    cap_max      INTEGER,
    CONSTRAINT pk_sessao PRIMARY KEY (id_sessao),
    CONSTRAINT fk_sessao_atividade
        FOREIGN KEY (id_atividade) REFERENCES atividade (id_atividade)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_sessao_espaco
        FOREIGN KEY (id_espaco) REFERENCES espaco (id_espaco)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_sessao_horario CHECK (horariot > horarioi),
    CONSTRAINT ck_sessao_cap_max CHECK (cap_max > 0),
    -- duas sessões não podem ocupar o mesmo espaço em horários que se sobrepõem
    -- (só vale para sessões já agendadas por completo)
    CONSTRAINT ex_sessao_conflito_espaco
        EXCLUDE USING gist (
            id_espaco WITH =,
            tsrange(data + horarioi, data + horariot) WITH &&
        )
        WHERE (data IS NOT NULL AND horarioi IS NOT NULL AND horariot IS NOT NULL)
);

-- =====================================================
-- LOG_SESSAO (entidade fraca de sessao)
-- =====================================================
CREATE TABLE log_sessao(
    id_sessao       INTEGER   NOT NULL,
    id_log          INTEGER GENERATED ALWAYS AS IDENTITY,
    dataalteracao   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_an         DATE      NOT NULL,
    horarioi_an     TIME      NOT NULL,
    horariot_an     TIME      NOT NULL,
    id_espaco_an    INTEGER   NOT NULL,
    CONSTRAINT pk_log_sessao PRIMARY KEY (id_sessao, id_log),
    CONSTRAINT fk_log_sessao_sessao
        FOREIGN KEY (id_sessao) REFERENCES sessao (id_sessao)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_log_sessao_espaco
        FOREIGN KEY (id_espaco_an) REFERENCES espaco (id_espaco)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_log_sessao_horario CHECK (horariot_an > horarioi_an)
);

-- =====================================================
-- TABELAS ASSOCIATIVAS (N:M)
-- =====================================================
CREATE TABLE participa(
    id_evento   INTEGER NOT NULL,
    id_particip INTEGER NOT NULL,
    CONSTRAINT pk_participa PRIMARY KEY (id_evento, id_particip),
    CONSTRAINT fk_participa_evento
        FOREIGN KEY (id_evento) REFERENCES evento (id_evento)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_participa_participante
        FOREIGN KEY (id_particip) REFERENCES participante (id_particip)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE inscreve(
    id_particip     INTEGER            NOT NULL,
    id_sessao       INTEGER            NOT NULL,
    papel_particip  papel_participante NOT NULL,
    status          status_inscricao   NOT NULL,
    CONSTRAINT pk_inscreve PRIMARY KEY (id_particip, id_sessao),
    CONSTRAINT fk_inscreve_participante
        FOREIGN KEY (id_particip) REFERENCES participante (id_particip)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_inscreve_sessao
        FOREIGN KEY (id_sessao) REFERENCES sessao (id_sessao)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE exige(
    id_atividade INTEGER NOT NULL,
    id_recurso   INTEGER NOT NULL,
    CONSTRAINT pk_exige PRIMARY KEY (id_atividade, id_recurso),
    CONSTRAINT fk_exige_atividade
        FOREIGN KEY (id_atividade) REFERENCES atividade (id_atividade)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_exige_recurso
        FOREIGN KEY (id_recurso) REFERENCES recurso (id_recurso)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE possui(
    id_recurso INTEGER NOT NULL,
    id_espaco  INTEGER NOT NULL,
    CONSTRAINT pk_possui PRIMARY KEY (id_recurso, id_espaco),
    CONSTRAINT fk_possui_recurso
        FOREIGN KEY (id_recurso) REFERENCES recurso (id_recurso)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_possui_espaco
        FOREIGN KEY (id_espaco) REFERENCES espaco (id_espaco)
        ON DELETE CASCADE ON UPDATE CASCADE
);
