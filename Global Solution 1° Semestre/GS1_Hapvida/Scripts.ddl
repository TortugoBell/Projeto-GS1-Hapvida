-- Gerado por Oracle SQL Developer Data Modeler 23.1.0.087.0806
--   em:        2023-11-24 02:03:44 BRT
--   site:      Oracle Database 11g
--   tipo:      Oracle Database 11g



-- predefined type, no DDL - MDSYS.SDO_GEOMETRY

-- predefined type, no DDL - XMLTYPE

CREATE TABLE t_gs1_agendamento (
    t_gs1_laudo_pct_cns  INTEGER NOT NULL,
    t_gs1_laudo_id_laudo INTEGER NOT NULL,
    id_agendamento       INTEGER NOT NULL,
    agd_data             TIMESTAMP NOT NULL,
    agd_status           VARCHAR2(10) NOT NULL
);

ALTER TABLE t_gs1_agendamento
    ADD CONSTRAINT t_gsi_agendamento_pk PRIMARY KEY ( t_gs1_laudo_pct_cns,
                                                      t_gs1_laudo_id_laudo,
                                                      id_agendamento );

CREATE TABLE t_gs1_historico (
    t_gs1_paciente_pct_cns INTEGER NOT NULL,
    id_historico           INTEGER NOT NULL,
    hist_data_comparecida  TIMESTAMP NOT NULL,
    hist_ubs_comparecida   INTEGER
);

ALTER TABLE t_gs1_historico ADD CONSTRAINT t_gsi_historico_pk PRIMARY KEY ( t_gs1_paciente_pct_cns,
                                                                            id_historico );

CREATE OR REPLACE PROCEDURE sp_gerar_datas_consulta (
    p_pct_cns    IN VARCHAR2,
    p_id_laudo   IN NUMBER,
    p_frequencia IN VARCHAR2,
    p_dt_inicial IN TIMESTAMP
) AS
    v_data_consulta TIMESTAMP;
    v_interval      NUMBER;
BEGIN
	--Exemplo com frequência semanal:
    v_interval :=
        CASE p_frequencia
            WHEN 'Semanal' THEN
                7
        END;
    FOR i IN 1..12 LOOP
        v_data_consulta := p_dt_inicial + ( v_interval * i );
        INSERT INTO t_gs1_agendamento (
            pct_cns,
            id_laudo,
            agd_data,
            agd_status
        ) VALUES (
            p_pct_cns,
            p_id_laudo,
            v_data_consulta,
            'Pendente'
        ); --Exemplo para status não confirmado
    END LOOP;

END sp_gerar_datas_consulta;
/

CREATE TABLE t_gs1_laudo (
    t_gs1_paciente_pct_cns INTEGER NOT NULL,
    id_laudo               INTEGER NOT NULL,
    ld_frequencia          VARCHAR2(20) NOT NULL,
    ld_dt_inicial          TIMESTAMP NOT NULL
);

ALTER TABLE t_gs1_laudo ADD CONSTRAINT t_gs1_laudo_pk PRIMARY KEY ( t_gs1_paciente_pct_cns,
                                                                    id_laudo );

CREATE TABLE t_gs1_paciente (
    pct_cns                    INTEGER NOT NULL,
    t_gs1_usuario_ubs_id_ubs   INTEGER NOT NULL,
    t_gs1_usuario_ubs_ubs_area INTEGER NOT NULL,
    pct_nm                     VARCHAR2(100) NOT NULL,
    pct_documento              VARCHAR2(64) NOT NULL,
    pct_telefone               VARCHAR2(32) NOT NULL
);

ALTER TABLE t_gs1_paciente ADD CONSTRAINT t_gs1_paciente_pk PRIMARY KEY ( pct_cns );

CREATE OR REPLACE TRIGGER trg_before_insert_notificacao BEFORE
    INSERT ON t_gs1_notificacao
    FOR EACH ROW
DECLARE
    v_numero_telefone VARCHAR2(20);
BEGIN
    SELECT
        pct_telefone
    INTO v_numero_telefone
    FROM
        t_gs1_paciente
    WHERE
        pct_cns = :new.pct_cns;

    IF v_numero_telefone IS NOT NULL THEN
        :new.ntf_numero_telefone := v_numero_telefone;
    ELSE
        :new.ntf_numero_telefone := 'Número de telefone não registrado';
    END IF;

    IF :new.ntf_mensagem IS NULL THEN
        :new.ntf_mensagem := 'Lembrete: Sua consulta está agendada para amanhã. Por favor, confirme sua presença.';
        --Mensagem exemplo. Posteriormente usar mensagem gerada pelo usuário através da UI
    END IF;

    :new.ntf_dt := :new.agd_data - 2;
    --Notificação aparece 2 dias antes do retorno esperado (configurável)
END;
/

CREATE TABLE t_gs1_notificacao ( 
--  ERROR: Column name length exceeds maximum allowed length(30) 
    t_gsi_agendamento_t_gs1_laudo_pct_cns  INTEGER NOT NULL, 
--  ERROR: Column name length exceeds maximum allowed length(30) 
    t_gsi_agendamento_t_gs1_laudo_id_laudo INTEGER NOT NULL, 
--  ERROR: Column name length exceeds maximum allowed length(30) 
    t_gsi_agendamento_id_agendamento       INTEGER NOT NULL,
    id_notificacao                         INTEGER NOT NULL,
    ntf_dt                                 TIMESTAMP NOT NULL,
    ntf_tipo                               VARCHAR2(8),
    ntf_mensagem                           VARCHAR2(255)
);

CREATE UNIQUE INDEX t_gsi_notificacao__idx ON
    t_gs1_notificacao (
        t_gsi_agendamento_id_agendamento
    ASC,
        t_gsi_agendamento_t_gs1_laudo_id_laudo
    ASC,
        t_gsi_agendamento_t_gs1_laudo_pct_cns
    ASC );

ALTER TABLE t_gs1_notificacao
    ADD CONSTRAINT t_gsi_notificacao_pk PRIMARY KEY ( t_gsi_agendamento_t_gs1_laudo_pct_cns,
                                                      t_gsi_agendamento_t_gs1_laudo_id_laudo,
                                                      t_gsi_agendamento_id_agendamento,
                                                      id_notificacao );

CREATE OR REPLACE FUNCTION hash_password (
    plain_text VARCHAR
) RETURN VARCHAR2 AS
    salt VARCHAR2(32);
BEGIN
    salt := dbms_random.string('X', 32); -- Gera um salt aleatório
    RETURN dbms_crypto.hash(utl_raw.cast_to_raw(plain_text || salt), 3); -- 3 representa o algoritmo SHA-256
END;
/

CREATE TABLE t_gs1_usuario_ubs (
    id_ubs      INTEGER NOT NULL,
    ubs_area    INTEGER NOT NULL,
    ubs_nm      VARCHAR2(100) NOT NULL,
    ubs_email   VARCHAR2(255) NOT NULL,
    ubs_senha   VARCHAR2(255) NOT NULL,
    ubs_contato VARCHAR2(20) NOT NULL
);
INSERT INTO UBS (UBS_Email, UBS_Senha, UBS_nm, UBS_Contato, UBS_Area)
VALUES
    (
        'ubs1@example.com',
        hash_password('senha123'),
        'Nome da UBS 1',
        '123456789',
        1
    ),
    (
        'ubs2@example.com',
        hash_password('outrasenha'),
        'Nome da UBS 2',
        '987654321',
        2
    )
;

ALTER TABLE t_gs1_usuario_ubs ADD CONSTRAINT t_gs1_usuario_ubs_pk PRIMARY KEY ( id_ubs,
                                                                                ubs_area );

ALTER TABLE t_gs1_laudo
    ADD CONSTRAINT t_gs1_laudo_t_gs1_paciente_fk FOREIGN KEY ( t_gs1_paciente_pct_cns )
        REFERENCES t_gs1_paciente ( pct_cns );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE t_gs1_paciente
    ADD CONSTRAINT t_gs1_paciente_t_gs1_usuario_ubs_fk FOREIGN KEY ( t_gs1_usuario_ubs_id_ubs,
                                                                     t_gs1_usuario_ubs_ubs_area )
        REFERENCES t_gs1_usuario_ubs ( id_ubs,
                                       ubs_area );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE t_gs1_agendamento
    ADD CONSTRAINT t_gsi_agendamento_t_gs1_laudo_fk FOREIGN KEY ( t_gs1_laudo_pct_cns,
                                                                  t_gs1_laudo_id_laudo )
        REFERENCES t_gs1_laudo ( t_gs1_paciente_pct_cns,
                                 id_laudo );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE t_gs1_historico
    ADD CONSTRAINT t_gsi_historico_t_gs1_paciente_fk FOREIGN KEY ( t_gs1_paciente_pct_cns )
        REFERENCES t_gs1_paciente ( pct_cns );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE t_gs1_notificacao
    ADD CONSTRAINT t_gsi_notificacao_t_gsi_agendamento_fk FOREIGN KEY ( t_gsi_agendamento_t_gs1_laudo_pct_cns,
                                                                        t_gsi_agendamento_t_gs1_laudo_id_laudo,
                                                                        t_gsi_agendamento_id_agendamento )
        REFERENCES t_gs1_agendamento ( t_gs1_laudo_pct_cns,
                                       t_gs1_laudo_id_laudo,
                                       id_agendamento );



-- Relatório do Resumo do Oracle SQL Developer Data Modeler: 
-- 
-- CREATE TABLE                             6
-- CREATE INDEX                             1
-- ALTER TABLE                             11
-- CREATE VIEW                              0
-- ALTER VIEW                               0
-- CREATE PACKAGE                           0
-- CREATE PACKAGE BODY                      0
-- CREATE PROCEDURE                         0
-- CREATE FUNCTION                          0
-- CREATE TRIGGER                           0
-- ALTER TRIGGER                            0
-- CREATE COLLECTION TYPE                   0
-- CREATE STRUCTURED TYPE                   0
-- CREATE STRUCTURED TYPE BODY              0
-- CREATE CLUSTER                           0
-- CREATE CONTEXT                           0
-- CREATE DATABASE                          0
-- CREATE DIMENSION                         0
-- CREATE DIRECTORY                         0
-- CREATE DISK GROUP                        0
-- CREATE ROLE                              0
-- CREATE ROLLBACK SEGMENT                  0
-- CREATE SEQUENCE                          0
-- CREATE MATERIALIZED VIEW                 0
-- CREATE MATERIALIZED VIEW LOG             0
-- CREATE SYNONYM                           0
-- CREATE TABLESPACE                        0
-- CREATE USER                              0
-- 
-- DROP TABLESPACE                          0
-- DROP DATABASE                            0
-- 
-- REDACTION POLICY                         0
-- 
-- ORDS DROP SCHEMA                         0
-- ORDS ENABLE SCHEMA                       0
-- ORDS ENABLE OBJECT                       0
-- 
-- ERRORS                                   7
-- WARNINGS                                 0
