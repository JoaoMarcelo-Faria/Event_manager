-- ============================================================================
-- 1. PROMOTOR, PESSOA_FISICA E ORGANIZACAO
-- Em bloco transacional devido ao trigger DEFERRABLE de participação total
-- ============================================================================
BEGIN;

-- IDs gerados automaticamente: 1 a 5
INSERT INTO promotor (nome, email_contato, tipo) VALUES
('Sociedade Brasileira de Computação', 'contato@sbc.org.br', 'ORGANIZACAO'),
('Comissão Organizadora SECOMP', 'secomp@universidade.edu.br', 'ORGANIZACAO'),
('Pró-Reitoria de Graduação e Extensão', 'feiras@universidades.edu.br', 'ORGANIZACAO'),
('TechEvents Brasil Ltda', 'comercial@techevents.com.br', 'ORGANIZACAO'),
('Prof. Dr. Carlos Eduardo Silva', 'carlos.silva@universidade.edu.br', 'PESSOA_FISICA');

INSERT INTO organizacao (cnpj, id_promotor) VALUES
('12345678000190', 1),
('45123789000155', 2),
('78912345000122', 3),
('98765432000110', 4);

INSERT INTO pessoa_fisica (cpf, id_promotor) VALUES
('11122233344', 5);

COMMIT;


-- ============================================================================
-- 2. EVENTO (8 Eventos: 4 SECOMP, 2 Feiras de Profissões, 2 Distintos)
-- IDs gerados automaticamente: 1 a 8
-- ============================================================================
INSERT INTO evento (id_promotor, titulo, datai, datat, edicao) VALUES
-- Família 1: Semana Acadêmica de Computação
(2, 'XIII Semana Acadêmica de Computação', '2023-05-10', '2023-05-12', 13),
(2, 'XIV Semana Acadêmica de Computação', '2024-05-10', '2024-05-12', 14),
(2, 'Semana Acadêmica de Computação XV', '2025-05-12', '2025-05-14', 15),
(2, 'Semana Acadêmica de Computação 26 - Edição XVI', '2026-05-10', '2026-05-12', 16),

-- Família 2: Feira de Profissões
(3, 'Feira de Profissões USP', '2026-06-15', '2026-06-17', 18),
(3, 'Feira de Profissões UNICAMP', '2026-07-20', '2026-07-22', 12),

-- Família 3: 2 Eventos com nomes completamente diferentes
(1, 'Simpósio Nacional de Bancos de Dados', '2026-08-20', '2026-08-22', 1),
(5, 'Treinamento Intensivo de Linux e Redes', '2026-09-05', '2026-09-06', 3);


-- ============================================================================
-- 3. ESPACO, RECURSO E POSSUI (Todos os espaços possuem recursos)
-- ============================================================================
-- IDs de espaço gerados: 1 a 5
INSERT INTO espaco (nome, capacidade) VALUES
('Auditório Principal', 150),
('Sala A (Bloco 1)', 30),
('Sala B (Bloco 1)', 20),
('Laboratório de Informática 01', 25),
('Área de Exposição Central', 300);

-- IDs de recurso gerados: 1 a 5
INSERT INTO recurso (nome, descricao) VALUES
('Projetor Multimídia', 'Projetor laser Full HD com entrada HDMI'),
('Sistema de Áudio', 'Mesa de som, caixas acústicas e 4 microfones sem fio'),
('Computadores de Bancada', 'Workstations com Linux, 16GB RAM e PostgreSQL instalado'),
('Acesso à Internet de Alta Velocidade', 'Rede Wi-Fi 6 dedicada e pontos de rede cabeada'),
('Quadro Branco Interativo', 'Lousa digital com canetas inteligentes');

INSERT INTO possui (id_recurso, id_espaco) VALUES
-- Espaço 1 (Auditório Principal): Projetor, Áudio e Internet
(1, 1), (2, 1), (4, 1),
-- Espaço 2 (Sala A): Todos os recursos
(1, 2), (2, 2), (3, 2), (4, 2), (5, 2),
-- Espaço 3 (Sala B): Projetor, Computadores, Internet e Quadro
(1, 3), (3, 3), (4, 3), (5, 3),
-- Espaço 4 (Lab 01): Projetor, Computadores, Internet e Quadro
(1, 4), (3, 4), (4, 4), (5, 4),
-- Espaço 5 (Área de Exposição): Projetor, Áudio e Internet
(1, 5), (2, 5), (4, 5);


-- ============================================================================
-- 4. ATIVIDADE E EXIGE (Todas exigem recursos)
-- IDs de atividade gerados: 1 a 24
-- ============================================================================
INSERT INTO atividade (id_evento, titulo, tipo, descricao, exige_inscri) VALUES
-- Evento 1: XIII SECOMP (Atividades 1, 2, 3)
(1, 'Palestra: Evolução dos Sistemas Operacionais', 'PALESTRA', 'Histórico e arquitetura de sistemas modernos.', FALSE),
(1, 'Minicurso de Linguagem C e Ponteiros', 'MINICURSO', 'Gerenciamento de memória e estruturas de dados em C.', TRUE),
(1, 'Workshop de Modelagem Relacional', 'WORKSHOP', 'Prática de MER e normalização em bancos de dados.', TRUE),

-- Evento 2: XIV SECOMP (Atividades 4, 5, 6)
(2, 'Palestra: Arquitetura de Microsserviços', 'PALESTRA', 'Padrões de distribuição e escalabilidade de sistemas.', FALSE),
(2, 'Minicurso de Desenvolvimento Web com TypeScript', 'MINICURSO', 'Tipagem estática e desenvolvimento full-stack.', TRUE),
(2, 'Mesa-Redonda: Mercado de TI no Brasil', 'MESA_REDONDA', 'Debate sobre carreiras e oportunidades locais e remotas.', FALSE),

-- Evento 3: XV SECOMP (Atividades 7, 8, 9)
(3, 'Palestra: Computação em Nuvem e Escalabilidade', 'PALESTRA', 'Infraestrutura moderna e serviços distribuídos.', FALSE),
(3, 'Introdução ao Git e GitHub', 'MINICURSO', 'Controle de versão colaborativo para iniciantes.', TRUE),
(3, 'Painel: Ética em Inteligência Artificial', 'PAINEL', 'Discussão sobre viés algorítmico e regulamentação.', FALSE),

-- Evento 4: XVI SECOMP (Atividades 10, 11, 12)
(4, 'Palestra de Abertura: O Futuro da IA e Dados', 'PALESTRA', 'Abertura oficial aberta a todos os inscritos no evento.', FALSE),
(4, 'Workshop de PostgreSQL', 'WORKSHOP', 'Prática de modelagem, tuning, GiST e triggers no PostgreSQL.', TRUE),
(4, 'Minicurso de Segurança em Redes e Docker', 'MINICURSO', 'Ambientes isolados em containers e práticas de DevSecOps.', TRUE),

-- Evento 5: Feira de Profissões USP (Atividades 13, 14, 15)
(5, 'Apresentação dos Cursos de Computação e SI', 'APRESENTACAO', 'Visão geral da grade curricular e atuação profissional.', FALSE),
(5, 'Mesa-Redonda: Vida Universitária e Pesquisa', 'MESA_REDONDA', 'Bolsas de iniciação científica, extensão e intercâmbio.', FALSE),
(5, 'Workshop: Meu Primeiro Algoritmo em Python', 'WORKSHOP', 'Introdução prática à programação para vestibulandos.', TRUE),

-- Evento 6: Feira de Profissões UNICAMP (Atividades 16, 17, 18)
(6, 'Palestra: Como Funciona o Vestibular e Ingressos', 'PALESTRA', 'Dicas sobre provas, cotas, bônus e modalidades de vagas.', FALSE),
(6, 'Apresentação de Projetos de Robótica e Jogos', 'APRESENTACAO', 'Demonstração prática de projetos das equipes de extensão.', FALSE),
(6, 'Oficina Prática de Lógica e Hardware', 'WORKSHOP', 'Conceitos de portas lógicas e circuitos digitais.', TRUE),

-- Evento 7: Simpósio Nacional de Bancos de Dados (Atividades 19, 20, 21)
(7, 'Painel: Bancos de Dados Grafo vs Relacionais', 'PAINEL', 'Discussão sobre performance em redes complexas.', FALSE),
(7, 'Workshop de Otimização de Consultas e Índices', 'WORKSHOP', 'Análise de planos de execução, B-Tree e GiST.', TRUE),
(7, 'Apresentação de Artigos Científicos em SGBDs', 'APRESENTACAO', 'Sessão técnica de trabalhos aprovados no simpósio.', FALSE),

-- Evento 8: Treinamento Intensivo de Linux e Redes (Atividades 22, 23, 24)
(8, 'Minicurso de Administração de Servidores Linux', 'MINICURSO', 'Permissões, systemd, gerenciamento de pacotes e shell.', TRUE),
(8, 'Workshop de Firewall, Roteamento e Redes', 'WORKSHOP', 'Configuração prática de sub-redes, iptables e nftables.', TRUE),
(8, 'Palestra de Encerramento: Carreira em DevSecOps', 'PALESTRA', 'Integração de segurança na esteira de infraestrutura.', FALSE);

-- Todas as 24 atividades exigem recursos compatíveis com os espaços de suas sessões
INSERT INTO exige (id_atividade, id_recurso) VALUES
-- Atividades teóricas/auditório/exposição exigem Projetor (1), Áudio (2) e Internet (4)
(1, 1), (1, 2), (1, 4),
(4, 1), (4, 2), (4, 4),
(6, 1), (6, 2), (6, 4),
(7, 1), (7, 2), (7, 4),
(9, 1), (9, 2), (9, 4),
(10, 1), (10, 2), (10, 4),
(13, 1), (13, 2), (13, 4),
(14, 1), (14, 2), (14, 4),
(16, 1), (16, 2), (16, 4),
(17, 1), (17, 2), (17, 4),
(19, 1), (19, 2), (19, 4),
(21, 1), (21, 2), (21, 4),
(24, 1), (24, 2), (24, 4),
-- Workshops e Minicursos práticos exigem Projetor (1), Computadores (3), Internet (4) e Quadro (5)
(2, 1), (2, 3), (2, 4), (2, 5),
(3, 1), (3, 3), (3, 4), (3, 5),
(5, 1), (5, 3), (5, 4), (5, 5),
(8, 1), (8, 3), (8, 4), (8, 5),
(11, 1), (11, 3), (11, 4), (11, 5),
(12, 1), (12, 3), (12, 4), (12, 5),
(15, 1), (15, 3), (15, 4), (15, 5),
(18, 1), (18, 3), (18, 4), (18, 5),
(20, 1), (20, 3), (20, 4), (20, 5),
(22, 1), (22, 3), (22, 4), (22, 5),
(23, 1), (23, 3), (23, 4), (23, 5);


-- ============================================================================
-- 5. SESSAO 
-- IDs gerados automaticamente: 1 a 25
-- ============================================================================
INSERT INTO sessao (id_atividade, id_espaco, data, horarioi, horariot, cap_max) VALUES
-- Evento 1 (XIII SECOMP - 2023): Sessões 1, 2, 3
(1, 1, '2023-05-10', '09:00:00', '11:00:00', 120),
(2, 4, '2023-05-10', '14:00:00', '17:00:00', 20),
(3, 2, '2023-05-11', '09:00:00', '12:00:00', 25),

-- Evento 2 (XIV SECOMP - 2024): Sessões 4, 5, 6
(4, 1, '2024-05-10', '09:00:00', '11:00:00', 150),
(5, 4, '2024-05-10', '14:00:00', '17:00:00', 25),
(6, 1, '2024-05-11', '14:00:00', '16:00:00', 150),

-- Evento 3 (XV SECOMP - 2025): Sessões 7, 8, 9
(7, 1, '2025-05-12', '09:00:00', '11:00:00', 150),
(8, 4, '2025-05-12', '14:00:00', '18:00:00', 20),
(9, 1, '2025-05-13', '10:00:00', '12:00:00', 150),

-- Evento 4 (XVI SECOMP - 2026): Sessões 10, 11, 12, 13 (Ativ 11 tem 2 sessões!)
(10, 1, '2026-05-10', '08:00:00', '09:00:00', 150),
(11, 2, '2026-05-10', '09:00:00', '12:00:00', 25),
(11, 3, '2026-05-10', '14:00:00', '17:00:00', 20),
(12, 4, '2026-05-11', '09:00:00', '12:00:00', 15),

-- Evento 5 (Feira de Profissões USP): Sessões 14, 15, 16
(13, 5, '2026-06-15', '09:00:00', '12:00:00', 250),
(14, 1, '2026-06-15', '14:00:00', '16:00:00', 150),
(15, 4, '2026-06-16', '09:00:00', '12:00:00', 25),

-- Evento 6 (Feira de Profissões UNICAMP): Sessões 17, 18, 19
(16, 1, '2026-07-20', '10:00:00', '12:00:00', 150),
(17, 5, '2026-07-20', '14:00:00', '17:00:00', 300),
(18, 2, '2026-07-21', '09:00:00', '12:00:00', 30),

-- Evento 7 (Simpósio Nacional de BD): Sessões 20, 21, 22
(19, 1, '2026-08-20', '10:00:00', '12:00:00', 120),
(20, 2, '2026-08-20', '14:00:00', '17:00:00', 30),
(21, 1, '2026-08-21', '09:00:00', '12:00:00', 150),

-- Evento 8 (Treinamento Intensivo de Linux e Redes): Sessões 23, 24, 25
(22, 4, '2026-09-05', '08:00:00', '12:00:00', 25),
(23, 3, '2026-09-05', '14:00:00', '18:00:00', 20),
(24, 1, '2026-09-06', '10:00:00', '12:00:00', 150);


-- ============================================================================
-- 6. LOG_SESSAO (5 Logs de alteração de programação)
-- ============================================================================
INSERT INTO log_sessao (id_sessao, dataalteracao, data_an, horarioi_an, horariot_an, id_espaco_an) VALUES
-- Log 1: Sessão 12 (Workshop PostgreSQL Tarde) mudou da Sala A (2) das 13h-16h para Sala B (3) das 14h-17h
(12, '2026-05-01 10:30:00', '2026-05-10', '13:00:00', '16:00:00', 2),
-- Log 2: Sessão 13 (Minicurso Docker) era no dia 10/05 à tarde na Sala B (3), mudou para 11/05 no Lab 01 (4)
(13, '2026-05-02 15:15:00', '2026-05-10', '14:00:00', '17:00:00', 3),
-- Log 3: Sessão 15 (Mesa-Redonda USP) passou por ajuste de horário e mudou da Área de Exposição (5) para o Auditório (1)
(15, '2026-06-05 09:00:00', '2026-06-15', '13:00:00', '15:00:00', 5),
-- Log 4: Sessão 20 (Painel Simpósio BD) teve o horário de início adiado das 08h-10h para 10h-12h
(20, '2026-08-10 14:20:00', '2026-08-20', '08:00:00', '10:00:00', 1),
-- Log 5: Sessão 24 (Workshop Firewall) mudou da Sala A (2) para a Sala B (3)
(24, '2026-08-28 11:10:00', '2026-09-05', '13:00:00', '17:00:00', 2);


-- ============================================================================
-- 7. PARTICIPANTE E PARTICIPA 
-- IDs gerados automaticamente: 1 a 16
-- ============================================================================
INSERT INTO participante (nome, documento, email) VALUES
('Dra. Ana Paula Souza', '10120230344', 'ana.souza@pesquisa.br'),
('MSc. Roberto Almeida', '20230340455', 'roberto.dba@empresa.com'),
('Profa. Dra. Helena Costa', '30340450566', 'helena.costa@universidade.edu.br'),
('Lucas Mendes', '40450560677', 'lucas.mendes@aluno.edu.br'),
('Mariana Oliveira', '50560670788', 'mariana.oli@aluno.edu.br'),
('Pedro Henrique Santos', '60670780899', 'pedro.santos@aluno.edu.br'),
('Camila Ferreira', '70780890900', 'camila.f@aluno.edu.br'),
('Gabriel Barbosa', '80890900111', 'gabriel.b@aluno.edu.br'),
('Juliana Lima', '90900111222', 'juliana.lima@aluno.edu.br'),
('Fernando Gomes', '01011222333', 'fernando.g@org.edu.br'),
('Rafael Cardoso', '12132343444', 'rafael.c@aluno.edu.br'),
('Beatriz Rocha', '23243454555', 'beatriz.rocha@aluno.edu.br'),
('Thiago Martins', '34354565666', 'thiago.m@empresa.com'),
('Larissa Dias', '45465676777', 'larissa.dias@aluno.edu.br'),
('Bruno Carvalho', '56576787888', 'bruno.carvalho@pesquisa.br'),
('Amanda Ribeiro', '67687898999', 'amanda.r@aluno.edu.br');

-- Alocação dos 16 participantes nos 8 eventos com repetições entre eventos
INSERT INTO participa (id_evento, id_particip) VALUES
-- Evento 1 (XIII SECOMP): Participantes 1 a 9
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9),
-- Evento 2 (XIV SECOMP): Participantes 2 a 10
(2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10),
-- Evento 3 (XV SECOMP): Participantes 3 a 11
(3, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11),
-- Evento 4 (XVI SECOMP): Todos os 16 participantes inscritos!
(4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6), (4, 7), (4, 8),
(4, 9), (4, 10), (4, 11), (4, 12), (4, 13), (4, 14), (4, 15), (4, 16),
-- Evento 5 (Feira USP): Participantes 1 a 9
(5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (5, 6), (5, 7), (5, 8), (5, 9),
-- Evento 6 (Feira UNICAMP): Participantes 8 a 16
(6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 14), (6, 15), (6, 16),
-- Evento 7 (Simpósio BD): Participantes 1 a 10
(7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 7), (7, 8), (7, 9), (7, 10),
-- Evento 8 (Treinamento Linux): Participantes 7 a 16
(8, 7), (8, 8), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (8, 14), (8, 15), (8, 16);


-- ============================================================================
-- 8. INSCREVE
-- ============================================================================
INSERT INTO inscreve (id_particip, id_sessao, papel_particip, status) VALUES
-- INSCREVE apenas para as 12 sessões de atividade que exigem inscrição:
-- Sessões 2, 3, 5, 8, 11, 12, 13, 16, 19, 21, 23 e 24)
-- SESSÃO 2 (Evento 1 - Minicurso C | exige_inscri = TRUE)
(2, 2, 'INSTRUTOR', 'CONFIRMADA'),
(4, 2, 'PARTICIPANTE', 'CONFIRMADA'), (5, 2, 'PARTICIPANTE', 'CONFIRMADA'),
(6, 2, 'PARTICIPANTE', 'EM ESPERA'),  (7, 2, 'PARTICIPANTE', 'EM ESPERA'),
(8, 2, 'PARTICIPANTE', 'CANCELADA'),  (9, 2, 'PARTICIPANTE', 'CANCELADA'),

-- SESSÃO 3 (Evento 1 - Workshop Modelagem | exige_inscri = TRUE)
(3, 3, 'INSTRUTOR', 'CONFIRMADA'),
(4, 3, 'PARTICIPANTE', 'CONFIRMADA'), (6, 3, 'PARTICIPANTE', 'CONFIRMADA'),
(5, 3, 'PARTICIPANTE', 'EM ESPERA'),  (8, 3, 'PARTICIPANTE', 'EM ESPERA'),
(7, 3, 'PARTICIPANTE', 'CANCELADA'),  (9, 3, 'PARTICIPANTE', 'CANCELADA'),

-- SESSÃO 5 (Evento 2 - Minicurso TypeScript | exige_inscri = TRUE)
(3, 5, 'INSTRUTOR', 'CONFIRMADA'),
(5, 5, 'PARTICIPANTE', 'CONFIRMADA'), (6, 5, 'PARTICIPANTE', 'CONFIRMADA'),
(7, 5, 'PARTICIPANTE', 'EM ESPERA'),  (8, 5, 'PARTICIPANTE', 'EM ESPERA'),
(9, 5, 'PARTICIPANTE', 'CANCELADA'),  (10, 5, 'PARTICIPANTE', 'CANCELADA'),

-- SESSÃO 8 (Evento 3 - Minicurso Git | exige_inscri = TRUE)
(10, 8, 'INSTRUTOR', 'CONFIRMADA'),
(4, 8, 'PARTICIPANTE', 'CONFIRMADA'), (5, 8, 'PARTICIPANTE', 'CONFIRMADA'),
(6, 8, 'PARTICIPANTE', 'EM ESPERA'),  (7, 8, 'PARTICIPANTE', 'EM ESPERA'),
(8, 8, 'PARTICIPANTE', 'CANCELADA'),  (11, 8, 'PARTICIPANTE', 'CANCELADA'),

-- SESSÃO 11 (Evento 4 - Workshop PostgreSQL Manhã | exige_inscri = TRUE)
(2, 11, 'INSTRUTOR', 'CONFIRMADA'),
(1, 11, 'PARTICIPANTE', 'CONFIRMADA'), (4, 11, 'PARTICIPANTE', 'CONFIRMADA'),
(11, 11, 'PARTICIPANTE', 'EM ESPERA'), (12, 11, 'PARTICIPANTE', 'EM ESPERA'),
(13, 11, 'PARTICIPANTE', 'CANCELADA'), (14, 11, 'PARTICIPANTE', 'CANCELADA'),

-- SESSÃO 12 (Evento 4 - Workshop PostgreSQL Tarde | exige_inscri = TRUE)
(2, 12, 'INSTRUTOR', 'CONFIRMADA'),
(6, 12, 'PARTICIPANTE', 'CONFIRMADA'), (7, 12, 'PARTICIPANTE', 'CONFIRMADA'),
(15, 12, 'PARTICIPANTE', 'EM ESPERA'), (16, 12, 'PARTICIPANTE', 'EM ESPERA'),
(8, 12, 'PARTICIPANTE', 'CANCELADA'),  (9, 12, 'PARTICIPANTE', 'CANCELADA'),

-- SESSÃO 13 (Evento 4 - Minicurso Docker | exige_inscri = TRUE)
(3, 13, 'INSTRUTOR', 'CONFIRMADA'),
(2, 13, 'PARTICIPANTE', 'CONFIRMADA'), (5, 13, 'PARTICIPANTE', 'CONFIRMADA'),
(6, 13, 'PARTICIPANTE', 'EM ESPERA'),  (7, 13, 'PARTICIPANTE', 'EM ESPERA'),
(9, 13, 'PARTICIPANTE', 'CANCELADA'),  (12, 13, 'PARTICIPANTE', 'CANCELADA'),

-- SESSÃO 16 (Evento 5 - Workshop Python USP | exige_inscri = TRUE)
(2, 16, 'INSTRUTOR', 'CONFIRMADA'),
(4, 16, 'PARTICIPANTE', 'CONFIRMADA'), (6, 16, 'PARTICIPANTE', 'CONFIRMADA'),
(5, 16, 'PARTICIPANTE', 'EM ESPERA'),  (8, 16, 'PARTICIPANTE', 'EM ESPERA'),
(7, 16, 'PARTICIPANTE', 'CANCELADA'),  (9, 16, 'PARTICIPANTE', 'CANCELADA'),

-- SESSÃO 19 (Evento 6 - Oficina Hardware UNICAMP | exige_inscri = TRUE)
(10, 19, 'INSTRUTOR', 'CONFIRMADA'),
(8, 19, 'PARTICIPANTE', 'CONFIRMADA'),  (11, 19, 'PARTICIPANTE', 'CONFIRMADA'),
(12, 19, 'PARTICIPANTE', 'EM ESPERA'),  (14, 19, 'PARTICIPANTE', 'EM ESPERA'),
(13, 19, 'PARTICIPANTE', 'CANCELADA'),  (16, 19, 'PARTICIPANTE', 'CANCELADA'),

-- SESSÃO 21 (Evento 7 - Workshop Otimização Consultas | exige_inscri = TRUE)
(2, 21, 'INSTRUTOR', 'CONFIRMADA'),
(4, 21, 'PARTICIPANTE', 'CONFIRMADA'), (6, 21, 'PARTICIPANTE', 'CONFIRMADA'),
(5, 21, 'PARTICIPANTE', 'EM ESPERA'),  (8, 21, 'PARTICIPANTE', 'EM ESPERA'),
(7, 21, 'PARTICIPANTE', 'CANCELADA'),  (10, 21, 'PARTICIPANTE', 'CANCELADA'),

-- SESSÃO 23 (Evento 8 - Minicurso Servidores Linux | exige_inscri = TRUE)
(13, 23, 'INSTRUTOR', 'CONFIRMADA'),
(7, 23, 'PARTICIPANTE', 'CONFIRMADA'),  (8, 23, 'PARTICIPANTE', 'CONFIRMADA'),
(9, 23, 'PARTICIPANTE', 'EM ESPERA'),   (10, 23, 'PARTICIPANTE', 'EM ESPERA'),
(11, 23, 'PARTICIPANTE', 'CANCELADA'),  (12, 23, 'PARTICIPANTE', 'CANCELADA'),

-- SESSÃO 24 (Evento 8 - Workshop Firewall e Redes | exige_inscri = TRUE)
(15, 24, 'INSTRUTOR', 'CONFIRMADA'),
(8, 24, 'PARTICIPANTE', 'CONFIRMADA'),  (9, 24, 'PARTICIPANTE', 'CONFIRMADA'),
(11, 24, 'PARTICIPANTE', 'EM ESPERA'),  (12, 24, 'PARTICIPANTE', 'EM ESPERA'),
(14, 24, 'PARTICIPANTE', 'CANCELADA'),  (16, 24, 'PARTICIPANTE', 'CANCELADA'),

-- INSCREVE os palestrantes das atividades que não exigem inscrição
(1, 1, 'PALESTRANTE', 'CONFIRMADA'),
(2, 4, 'PALESTRANTE', 'CONFIRMADA'),
(2, 6, 'PALESTRANTE', 'CONFIRMADA'),
(3, 7, 'PALESTRANTE', 'CONFIRMADA'),
(3, 9, 'PALESTRANTE', 'CONFIRMADA'),
(1, 10, 'PALESTRANTE', 'CONFIRMADA'),
(1, 14, 'PALESTRANTE', 'CONFIRMADA'),
(3, 15, 'PALESTRANTE', 'CONFIRMADA'),
(15, 17, 'PALESTRANTE', 'CONFIRMADA'),
(13, 18, 'PALESTRANTE', 'CONFIRMADA'),
(1, 20, 'PALESTRANTE', 'CONFIRMADA'),
(3, 22, 'PALESTRANTE', 'CONFIRMADA'),
(10, 25, 'PALESTRANTE', 'CONFIRMADA');