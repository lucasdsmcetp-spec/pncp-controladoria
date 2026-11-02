CREATE DATABASE IF NOT EXISTS pncp_controladoria
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE pncp_controladoria;

CREATE TABLE IF NOT EXISTS dim_orgao (
    sk_orgao INT NOT NULL,
    cnpj_orgao VARCHAR(14) NULL,
    nome_orgao VARCHAR(255) NULL,
    poder VARCHAR(30) NULL,
    PRIMARY KEY (sk_orgao),
    UNIQUE KEY uq_dim_orgao_cnpj (cnpj_orgao)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dim_fornecedor (
    sk_fornecedor INT NOT NULL,
    ni_fornecedor VARCHAR(20) NOT NULL,
    nome_fornecedor VARCHAR(255) NULL,
    tipo_pessoa VARCHAR(10) NULL,
    porte VARCHAR(100) NULL,
    PRIMARY KEY (sk_fornecedor),
    UNIQUE KEY uq_dim_fornecedor_ni (ni_fornecedor)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dim_modalidade (
    sk_modalidade INT NOT NULL,
    modalidade_id INT NOT NULL,
    nome_modalidade VARCHAR(100) NULL,
    PRIMARY KEY (sk_modalidade),
    UNIQUE KEY uq_dim_modalidade_id (modalidade_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dim_localidade (
    sk_localidade INT NOT NULL,
    uf_sigla CHAR(2) NOT NULL,
    uf_nome VARCHAR(50) NULL,
    regiao VARCHAR(50) NULL,
    PRIMARY KEY (sk_localidade),
    UNIQUE KEY uq_dim_localidade_uf (uf_sigla)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS fato_item_contratado (
    numero_controle_pncp VARCHAR(100) NOT NULL,
    numero_item INT NOT NULL,
    sk_orgao INT NOT NULL,
    sk_fornecedor INT NOT NULL,
    sk_modalidade INT NOT NULL,
    sk_localidade INT NOT NULL,
    data_publicacao DATE NULL,
    data_homologacao DATE NULL,
    descricao_item TEXT NULL,
    perfil_gasto VARCHAR(50) NULL,
    quantidade DECIMAL(20, 4) NULL,
    valor_unitario_estimado DECIMAL(20, 2) NULL,
    valor_total_estimado DECIMAL(20, 2) NULL,
    valor_unitario_homologado DECIMAL(20, 2) NULL,
    valor_total_homologado DECIMAL(20, 2) NULL,
    comparavel TINYINT NOT NULL,
    economia_valor DECIMAL(20, 2) NULL,
    dias_ciclo INT NULL,
    PRIMARY KEY (numero_controle_pncp, numero_item),
    KEY ix_fato_orgao (sk_orgao),
    KEY ix_fato_fornecedor (sk_fornecedor),
    KEY ix_fato_modalidade (sk_modalidade),
    KEY ix_fato_localidade (sk_localidade),
    CONSTRAINT fk_fato_orgao
        FOREIGN KEY (sk_orgao) REFERENCES dim_orgao (sk_orgao),
    CONSTRAINT fk_fato_fornecedor
        FOREIGN KEY (sk_fornecedor) REFERENCES dim_fornecedor (sk_fornecedor),
    CONSTRAINT fk_fato_modalidade
        FOREIGN KEY (sk_modalidade) REFERENCES dim_modalidade (sk_modalidade),
    CONSTRAINT fk_fato_localidade
        FOREIGN KEY (sk_localidade) REFERENCES dim_localidade (sk_localidade)
) ENGINE=InnoDB;
