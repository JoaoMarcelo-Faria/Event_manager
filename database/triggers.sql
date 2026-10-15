TRIGGER 1:

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
    FOR EACH ROW EXECUTE FUNCTION fn_checa_especializacao_promotor()



-- =====================================================
-- TRIGGER 2: Log automático de alteração de sessão
-- Grava o estado ANTERIOR sempre que data, horário ou espaço mudarem,
-- mas só se a sessão já estava agendada por completo (log exige NOT NULL)
-- =====================================================
CREATE FUNCTION fn_log_sessao() RETURNS trigger AS $$
BEGIN
    INSERT INTO log_sessao (id_sessao, data_an, horarioi_an, horariot_an, id_espaco_an)
    VALUES (OLD.id_sessao, OLD.data, OLD.horarioi, OLD.horariot, OLD.id_espaco);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sessao_log
    AFTER UPDATE OF data, horarioi, horariot, id_espaco ON sessao
    FOR EACH ROW
    WHEN (
        OLD.data IS NOT NULL
        AND OLD.horarioi IS NOT NULL
        AND OLD.horariot IS NOT NULL
        AND (OLD.data      IS DISTINCT FROM NEW.data
          OR OLD.horarioi  IS DISTINCT FROM NEW.horarioi
          OR OLD.horariot  IS DISTINCT FROM NEW.horariot
          OR OLD.id_espaco IS DISTINCT FROM NEW.id_espaco)
    )
    EXECUTE FUNCTION fn_log_sessao();

-- =====================================================
-- TRIGGER 3: cap_max da sessão não pode exceder a capacidade do espaço
-- =====================================================
CREATE FUNCTION fn_checa_cap_sessao() RETURNS trigger AS $$
DECLARE
    v_capacidade INTEGER;
BEGIN
    IF NEW.cap_max IS NOT NULL THEN
        SELECT capacidade INTO v_capacidade
        FROM espaco WHERE id_espaco = NEW.id_espaco;

        IF NEW.cap_max > v_capacidade THEN
            RAISE EXCEPTION 'cap_max (%) excede a capacidade do espaco (%)',
                NEW.cap_max, v_capacidade;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sessao_cap_espaco
    BEFORE INSERT OR UPDATE OF cap_max, id_espaco ON sessao
    FOR EACH ROW EXECUTE FUNCTION fn_checa_cap_sessao();

-- =====================================================
-- TRIGGER 4: sessão precisa ocorrer dentro do período do evento
-- =====================================================
CREATE FUNCTION fn_checa_periodo_sessao() RETURNS trigger AS $$
DECLARE
    v_ini DATE;
    v_fim DATE;
BEGIN
    SELECT e.datai, e.datat INTO v_ini, v_fim
    FROM atividade a
    JOIN evento e ON e.id_evento = a.id_evento
    WHERE a.id_atividade = NEW.id_atividade;

    IF NEW.data IS NOT NULL AND (
          (v_ini IS NOT NULL AND NEW.data < v_ini)
       OR (v_fim IS NOT NULL AND NEW.data > v_fim)) THEN
        RAISE EXCEPTION 'Data da sessao (%) fora do periodo do evento (% a %)',
            NEW.data, v_ini, v_fim;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sessao_periodo_evento
    BEFORE INSERT OR UPDATE OF data, id_atividade ON sessao
    FOR EACH ROW EXECUTE FUNCTION fn_checa_periodo_sessao();

-- =====================================================
-- TRIGGER 5: limite de vagas na inscrição da sessão
-- Só conta quem entra como PARTICIPANTE (palestrantes não ocupam vaga)
-- =====================================================
CREATE FUNCTION fn_checa_lotacao_sessao() RETURNS trigger AS $$
DECLARE
    v_cap       INTEGER;
    v_inscritos INTEGER;
BEGIN
    IF NEW.papel_particip = 'PARTICIPANTE' THEN
        -- FOR UPDATE trava a sessão para evitar duas inscrições simultâneas na última vaga
        SELECT cap_max INTO v_cap
        FROM sessao WHERE id_sessao = NEW.id_sessao FOR UPDATE;

        IF v_cap IS NOT NULL THEN
            SELECT COUNT(*) INTO v_inscritos
            FROM inscreve
            WHERE id_sessao = NEW.id_sessao
              AND papel_particip = 'PARTICIPANTE';

            IF v_inscritos >= v_cap THEN
                RAISE EXCEPTION 'Sessao % lotada (% vagas)', NEW.id_sessao, v_cap;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inscreve_lotacao
    BEFORE INSERT ON inscreve
    FOR EACH ROW EXECUTE FUNCTION fn_checa_lotacao_sessao();

-- =====================================================
-- TRIGGER 6: inscrição em sessão exige inscrição prévia no evento
-- (aplica só ao papel PARTICIPANTE)
-- =====================================================
CREATE FUNCTION fn_checa_inscricao_evento() RETURNS trigger AS $$
BEGIN
    IF NEW.papel_particip = 'PARTICIPANTE' AND NOT EXISTS (
        SELECT 1
        FROM sessao s
        JOIN atividade a ON a.id_atividade = s.id_atividade
        JOIN participa p ON p.id_evento = a.id_evento
        WHERE s.id_sessao   = NEW.id_sessao
          AND p.id_particip = NEW.id_particip
    ) THEN
        RAISE EXCEPTION 'Participante % nao esta inscrito no evento da sessao %',
            NEW.id_particip, NEW.id_sessao;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inscreve_participa_evento
    BEFORE INSERT ON inscreve
    FOR EACH ROW EXECUTE FUNCTION fn_checa_inscricao_evento();

-- =====================================================
-- TRIGGER 7: espaço da sessão precisa ter os recursos que a atividade exige
-- Deferido: dá tempo de inserir sessao e exige na mesma transação
-- =====================================================
CREATE FUNCTION fn_checa_recursos_sessao() RETURNS trigger AS $$
DECLARE
    v_faltando VARCHAR(50);
BEGIN
    SELECT r.nome INTO v_faltando
    FROM exige x
    JOIN recurso r ON r.id_recurso = x.id_recurso
    WHERE x.id_atividade = NEW.id_atividade
      AND NOT EXISTS (
          SELECT 1 FROM possui p
          WHERE p.id_recurso = x.id_recurso
            AND p.id_espaco  = NEW.id_espaco
      )
    LIMIT 1;

    IF v_faltando IS NOT NULL THEN
        RAISE EXCEPTION 'Espaco % nao possui o recurso exigido: %',
            NEW.id_espaco, v_faltando;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_sessao_recursos
    AFTER INSERT OR UPDATE OF id_atividade, id_espaco ON sessao
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_checa_recursos_sessao();

-- =====================================================
-- TRIGGER 8: só permite inscrição em sessões de atividades que exigem inscrição
-- (aplica só ao papel PARTICIPANTE, como os triggers 4 e 5)
-- =====================================================
CREATE FUNCTION fn_checa_exige_inscricao() RETURNS trigger AS $$
DECLARE
    v_exige BOOLEAN;
BEGIN
    IF NEW.papel_particip = 'PARTICIPANTE' THEN
        SELECT a.exige_inscri INTO v_exige
        FROM sessao s
        JOIN atividade a ON a.id_atividade = s.id_atividade
        WHERE s.id_sessao = NEW.id_sessao;

        IF v_exige IS NOT TRUE THEN
            RAISE EXCEPTION 'A atividade da sessao % nao exige inscricao adicional', NEW.id_sessao;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inscreve_exige_inscricao
    BEFORE INSERT ON inscreve
    FOR EACH ROW EXECUTE FUNCTION fn_checa_exige_inscricao();
