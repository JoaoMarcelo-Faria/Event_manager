BEGIN;

-- ============================================================================
-- 1. PROMOTOR, PESSOA_FISICA E ORGANIZACAO
-- ============================================================================
-- IDs gerados automaticamente: 1, 2, 3, 4
INSERT INTO promotor (nome, email_contato, tipo) VALUES
('Sociedade Brasileira de Computação', 'contato@sbc.org.br', 'ORGANIZACAO'),
('TechEvents Brasil Ltda', 'comercial@techevents.com.br', 'ORGANIZACAO'),
('Prof. Dr. Carlos Eduardo Silva', 'carlos.silva@universidade.edu.br', 'PESSOA_FISICA'),
('Comissão Organizadora SECOMP', 'secomp@universidade.edu.br', 'ORGANIZACAO');

-- Subtabela de Organizações (Apenas 14 dígitos numéricos para passar no CHECK)
INSERT INTO organizacao (cnpj, id_promotor) VALUES
('12345678000190', 1),
('98765432000110', 2),
('45123789000155', 4);

-- Subtabela de Pessoa Física (Apenas 11 dígitos numéricos para passar no CHECK)
INSERT INTO pessoa_fisica (cpf, id_promotor) VALUES
('11122233344', 3);


-- ============================================================================
-- 2. EVENTO
-- Eventos da mesma família possuem o mesmo título e se diferenciam por "edicao"
-- IDs gerados automaticamente: 1, 2, 3, 4, 5
-- ============================================================================
INSERT INTO evento (id_promotor, titulo, datai, datat, edicao) VALUES
(4, 'Semana Acadêmica de Computação 24', '2024-05-10', '2024-05-14', 14),
(4, 'Semana Acadêmica de Computação 25', '2025-05-12', '2025-05-16', 15),
(4, 'Semana Acadêmica de Computação 26', '2026-05-10', '2026-05-12', 16),
(4, 'A Semana Acadêmica de Computação - Anos 2000', '2026-05-10', '2026-05-12', 17),
(1, 'Simpósio Nacional de Bancos de Dados', '2026-08-20', '2026-08-22', 1),
(3, 'Treinamento Intensivo de Linux e Redes', '2026-09-05', '2026-09-06', 3);


-- ============================================================================
-- 3. ESPACO, RECURSO E POSSUI
-- ============================================================================
-- IDs de espaço gerados: 1, 2, 3, 4, 5
INSERT INTO espaco (nome, capacidade) VALUES
('Auditório Principal', 150),
('Sala A (Bloco 1)', 30),
('Sala B (Bloco 1)', 20),
('Laboratório de Informática 01', 5), -- Capacidade baixa para testar lotação/fila de espera
('Área de Exposição Central', 300);

-- IDs de recurso gerados: 1, 2, 3, 4, 5
INSERT INTO recurso (nome, descricao) VALUES
('Projetor Multimídia', 'Projetor laser Full HD com entrada HDMI'),
('Sistema de Áudio', 'Mesa de som, caixas acústicas e 4 microfones sem fio'),
('Computadores de Bancada', 'Workstations com Linux, 16GB RAM e PostgreSQL instalado'),
('Acesso à Internet de Alta Velocidade', 'Rede Wi-Fi 6 dedicada e pontos de rede cabeada'),
('Quadro Branco Interativo', 'Lousa digital com canetas inteligentes');

INSERT INTO possui (id_recurso, id_espaco) VALUES
-- Auditório Principal (1): Projetor, Áudio e Internet
(1, 1), (2, 1), (4, 1),
-- Sala A (2): Projetor, Computadores, Internet e Quadro
(1, 2), (3, 2), (4, 2), (5, 2),
-- Sala B (3): Projetor, Computadores e Internet
(1, 3), (3, 3), (4, 3),
-- Lab 01 (4): Projetor, Computadores e Internet
(1, 4), (3, 4), (4, 4),
-- Área de Exposição (5): Áudio e Internet
(2, 5), (4, 5);


-- ============================================================================
-- 4. ATIVIDADE E EXIGE
-- ============================================================================
-- IDs de atividade gerados: 1, 2, 3, 4, 5, 6, 7
INSERT INTO atividade (id_evento, titulo, tipo, descricao, exige_inscri) VALUES
-- Atividades da 16ª SECOMP (id_evento = 3)
(3, 'Palestra de Abertura: O Futuro da IA e Dados', 'PALESTRA', 'Abertura oficial aberta a todos os inscritos no evento.', FALSE),
(3, 'Workshop de PostgreSQL', 'WORKSHOP', 'Prática de modelagem, tuning, GiST e triggers no PostgreSQL.', TRUE),
(3, 'Minicurso de Segurança em Redes e Docker', 'MINICURSO', 'Ambientes isolados e práticas de DevSecOps.', TRUE),
(3, 'Mesa-Redonda: Carreira Acadêmica vs Indústria', 'MESA_REDONDA', 'Debate aberto com profissionais e pesquisadores.', FALSE),
(3, 'Apresentação de Trabalhos de Iniciação Científica', 'APRESENTACAO', 'Sessão de pôsteres e apresentações rápidas.', FALSE),
-- Atividade do Simpósio de BD (id_evento = 4)
(4, 'Painel: Bancos de Dados Grafo vs Relacionais', 'PAINEL', 'Discussão sobre performance em redes complexas.', FALSE),
-- Atividade da edição anterior - 15ª SECOMP (id_evento = 2)
(2, 'Introdução ao Git e GitHub', 'MINICURSO', 'Controle de versão para iniciantes.', TRUE);

INSERT INTO exige (id_atividade, id_recurso) VALUES
(1, 1), (1, 2),         -- Palestra exige Projetor e Sistema de Áudio
(2, 1), (2, 3), (2, 4), -- Workshop de PostgreSQL exige Projetor, Computadores e Internet
(3, 1), (3, 3), (3, 4), -- Minicurso Docker exige Projetor, Computadores e Internet
(4, 2),                 -- Mesa-redonda exige Sistema de Áudio
(5, 1),                 -- Apresentação exige Projetor
(6, 1), (6, 2);         -- Painel exige Projetor e Sistema de Áudio


-- ============================================================================
-- 5. SESSAO E LOG_SESSAO
-- Respeitando a constraint EXCLUDE USING gist (sem choque de horário no mesmo espaço)
-- e demonstrando também sessão ainda em planejamento (data/horário NULL).
-- ============================================================================
-- IDs de sessão gerados: 1, 2, 3, 4, 5, 6, 7, 8
INSERT INTO sessao (id_atividade, id_espaco, data, horarioi, horariot, cap_max) VALUES
-- Sessão 1: Palestra de Abertura (cap_max 200 > capacidade do Auditório 150 -> limite real = 150)
(1, 1, '2026-05-10', '08:00:00', '09:00:00', 200),

-- Sessões 2 e 3: Workshop de PostgreSQL (duas realizações da mesma atividade!)
-- Sessão 2: Manhã na Sala A (cap_max 25 < capacidade da Sala A 30 -> limite real = 25)
(2, 2, '2026-05-10', '09:00:00', '12:00:00', 25),
-- Sessão 3: Tarde na Sala B (cap_max 25 > capacidade da Sala B 20 -> limite real = 20)
(2, 3, '2026-05-10', '14:00:00', '17:00:00', 25),

-- Sessão 4: Minicurso Docker no Lab 01 (cap_max = 3, capacidade Lab = 5 -> lota com 3 inscritos!)
(3, 4, '2026-05-11', '09:00:00', '12:00:00', 3),

-- Sessão 5: Mesa-Redonda no Auditório (sofreu alterações registradas em log_sessao)
(4, 1, '2026-05-11', '14:00:00', '16:00:00', 150),

-- Sessão 6: Apresentação de IC (SESSÃO EM PLANEJAMENTO: data e horários NULL!)
(5, 5, NULL, NULL, NULL, 100),

-- Sessão 7: Painel no Simpósio de BD
(6, 1, '2026-08-20', '10:00:00', '12:00:00', 120),

-- Sessão 8: Sessão histórica da 15ª SECOMP em 2025
(7, 4, '2025-05-12', '14:00:00', '18:00:00', 5);

-- Histórico de alterações (id_log é gerado automaticamente)
INSERT INTO log_sessao (id_sessao, dataalteracao, data_an, horarioi_an, horariot_an, id_espaco_an) VALUES
-- Sessão 3 (Workshop PostgreSQL Tarde) era das 13h às 16h na Sala A (2), mudou para 14h-17h na Sala B (3)
(3, '2026-05-01 10:30:00', '2026-05-10', '13:00:00', '16:00:00', 2),

-- Sessão 5 (Mesa-Redonda) teve duas mudanças: primeiro de sala/horário, depois de data
(5, '2026-05-02 15:15:00', '2026-05-10', '16:00:00', '18:00:00', 2),
(5, '2026-05-04 09:00:00', '2026-05-11', '10:00:00', '12:00:00', 1);


-- ============================================================================
-- 6. PARTICIPANTE, PARTICIPA E INSCREVE
-- ============================================================================
-- IDs de participante gerados: 1 a 10
INSERT INTO participante (nome, documento, email) VALUES
('Dra. Ana Paula Souza', '22233344455', 'ana.souza@pesquisa.br'),
('MSc. Roberto Almeida', '33344455566', 'roberto.dba@empresa.com'),
('Profa. Dra. Helena Costa', '44455566677', 'helena.costa@universidade.edu.br'),
('Lucas Mendes', '55566677788', 'lucas.mendes@aluno.edu.br'),
('Mariana Oliveira', '66677788899', 'mariana.oli@aluno.edu.br'),
('Pedro Henrique Santos', '77788899900', 'pedro.santos@aluno.edu.br'),
('Camila Ferreira', '88899900011', 'camila.f@aluno.edu.br'),
('Gabriel Barbosa', '99900011122', 'gabriel.b@aluno.edu.br'),
('Juliana Lima', '00011122233', 'juliana.lima@aluno.edu.br'),
('Fernando Gomes', '12345678901', 'fernando.g@org.edu.br');

-- Relacionamento Participa (Inscrição geral no Evento)
INSERT INTO participa (id_evento, id_particip) VALUES
-- Todos os 10 inscritos na 16ª SECOMP (id_evento = 3)
(3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10),
-- Participantes que estiveram na 15ª SECOMP (id_evento = 2)
(2, 4), (2, 5), (2, 10),
-- Inscritos no Simpósio de BD (id_evento = 4)
(4, 1), (4, 2), (4, 3), (4, 6);

-- Relacionamento Inscreve (Inscrição e Papéis nas Sessões usando os ENUMs definidos)
INSERT INTO inscreve (id_particip, id_sessao, papel_particip, status) VALUES
-- SESSÃO 1 (Palestra de Abertura)
(1, 1, 'PALESTRANTE', 'CONFIRMADA'),
(10, 1, 'ORGANIZADOR', 'CONFIRMADA'),

-- SESSÃO 2 (Workshop PostgreSQL Manhã)
-- Dra. Ana (1) foi PALESTRANTE na Sessão 1 e agora é PARTICIPANTE (ouvinte) na Sessão 2!
(2, 2, 'INSTRUTOR', 'CONFIRMADA'),
(10, 2, 'ORGANIZADOR', 'CONFIRMADA'),
(1, 2, 'PARTICIPANTE', 'CONFIRMADA'),
(4, 2, 'PARTICIPANTE', 'CONFIRMADA'),
(5, 2, 'PARTICIPANTE', 'CONFIRMADA'),

-- SESSÃO 3 (Workshop PostgreSQL Tarde - Teve alteração no log_sessao)
(2, 3, 'INSTRUTOR', 'CONFIRMADA'),
(6, 3, 'PARTICIPANTE', 'CONFIRMADA'),
(7, 3, 'PARTICIPANTE', 'CONFIRMADA'),
(8, 3, 'PARTICIPANTE', 'CANCELADA'), -- Demonstra desistência após mudança de horário!

-- SESSÃO 4 (Minicurso Docker - cap_max = 3 vagas)
-- Demonstra lotação atingida (3 CONFIRMADA), fila (2 EM ESPERA) e desistência (1 CANCELADA)
(3, 4, 'INSTRUTOR', 'CONFIRMADA'),
(2, 4, 'PARTICIPANTE', 'CONFIRMADA'), -- Vaga 1 (Roberto foi instrutor na 2/3 e é aluno na 4)
(4, 4, 'PARTICIPANTE', 'CONFIRMADA'), -- Vaga 2
(5, 4, 'PARTICIPANTE', 'CONFIRMADA'), -- Vaga 3 (Lotou!)
(6, 4, 'PARTICIPANTE', 'EM ESPERA'),  -- Fila de espera 1
(7, 4, 'PARTICIPANTE', 'EM ESPERA'),  -- Fila de espera 2
(9, 4, 'PARTICIPANTE', 'CANCELADA'),

-- SESSÃO 5 (Mesa-Redonda)
(1, 5, 'PALESTRANTE', 'CONFIRMADA'),
(2, 5, 'PALESTRANTE', 'CONFIRMADA'),
(3, 5, 'PALESTRANTE', 'CONFIRMADA'),
(10, 5, 'ORGANIZADOR', 'CONFIRMADA'),

-- SESSÃO 7 (Painel Simpósio de BD)
(1, 7, 'PALESTRANTE', 'CONFIRMADA'),
(3, 7, 'PALESTRANTE', 'CONFIRMADA'),

-- SESSÃO 8 (Edição de 2025)
(10, 8, 'INSTRUTOR', 'CONFIRMADA'),
(4, 8, 'PARTICIPANTE', 'CONFIRMADA'),
(5, 8, 'PARTICIPANTE', 'CONFIRMADA');

COMMIT;