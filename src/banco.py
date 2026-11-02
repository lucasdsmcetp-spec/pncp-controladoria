"""
banco.py  -  conexao e utilitarios do MySQL
-------------------------------------------
Mesmo papel do banco.py dos projetos anteriores: abrir conexao, executar SQL e
inserir em lote. Aqui acrescentamos executar_script() para rodar os arquivos
da pasta sql/ (o schema vive nos .sql, nao no Python).
"""

import re

from importlib import import_module

try:
    mysql_connector = import_module("mysql.connector")
    Error = mysql_connector.Error
except ModuleNotFoundError:
    mysql_connector = None
    Error = Exception

if __package__:
    from src import config
else:
    import config


def conectar(com_database=True):
    """Abre a conexao. com_database=False serve para rodar o CREATE DATABASE."""
    if mysql_connector is None:
        raise RuntimeError(
            "Dependencia ausente: instale mysql-connector-python "
            "com 'pip install mysql-connector-python'."
        )
    cfg = dict(config.MYSQL_CONFIG)
    if com_database:
        cfg["database"] = config.MYSQL_DATABASE
    try:
        return mysql_connector.connect(**cfg, charset="utf8mb4")
    except Error as erro:
        raise RuntimeError(
            f"Nao foi possivel conectar ao MySQL em {cfg['host']}:{cfg['port']}. "
            f"Confira o arquivo .env e se o servico esta no ar. Detalhe: {erro}"
        )


def _separar_comandos(sql):
    """Quebra um script .sql em comandos (remove comentarios '-- ...' e separa por ';')."""
    sem_comentarios = re.sub(r"--[^\n]*", "", sql)
    return [c.strip() for c in sem_comentarios.split(";") if c.strip()]


def executar_script(conexao, caminho):
    """Executa todos os comandos de um arquivo .sql, em ordem."""
    cursor = conexao.cursor()
    for comando in _separar_comandos(caminho.read_text(encoding="utf-8")):
        cursor.execute(comando)
    conexao.commit()
    cursor.close()


def executar(conexao, sql, params=None):
    cursor = conexao.cursor()
    cursor.execute(sql, params)
    conexao.commit()
    cursor.close()


def consultar(conexao, sql, params=None):
    """SELECT -> lista de tuplas."""
    cursor = conexao.cursor()
    cursor.execute(sql, params)
    linhas = cursor.fetchall()
    cursor.close()
    return linhas


def inserir_em_lote(conexao, sql_insert, linhas):
    """Insere varias linhas de uma vez (executemany). 'sql_insert' usa %s."""
    if not linhas:
        return
    cursor = conexao.cursor()
    cursor.executemany(sql_insert, linhas)
    conexao.commit()
    cursor.close()
