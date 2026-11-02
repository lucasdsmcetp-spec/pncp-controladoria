"""auditoria.py - CONTA os problemas dos dados BRUTOS (antes de limpar). Rode: python -m src.auditoria"""
import re
import pandas as pd
from src import config, limpeza

def ler(n): return pd.read_csv(config.PASTA_RAW / f"{n}.csv", dtype=str, keep_default_na=False)
def mostrar(titulo, valor): print(f"  {titulo:<58}{valor:>8}")

def documento(serie, nome, tipo=None):
    s = serie.str.strip(); vazio = s == ""
    mostrar(f"{nome}: com máscara (. / -)", int(s.str.contains(r"[./-]").sum()))
    dig = s.map(lambda v: "".join(c for c in v if c.isdigit()))
    tam = 14 if tipo is None else None
    if tipo is None:
        mostrar(f"{nome}: zero à esquerda perdido (<14 dígitos)", int(((dig.str.len() > 0) & (dig.str.len() < 14)).sum()))
    limpo = [limpeza.limpar_documento(v, t) for v, t in zip(serie, tipo if tipo is not None else ["PJ"] * len(serie))]
    mostrar(f"{nome}: vazio/lixo/impossível (viram nulo)", int(sum(x is None for x in limpo)))

def numero(serie, nome):
    s = serie.str.strip()
    mostrar(f"{nome}: com 'R$'", int(s.str.contains("R\\$").sum()))
    mostrar(f"{nome}: com vírgula decimal", int(s.str.contains(",").sum()))
    mostrar(f"{nome}: negativo com parênteses ou sinal no fim", int(s.str.contains(r"^\(|-$").sum()))
    mostrar(f"{nome}: não converte (N/A, vazio, lixo)", int(sum(limpeza.converter_numero(v) is None for v in serie)))

def data(serie, nome):
    pad = {"ISO com hora": r"^\d{4}-\d{2}-\d{2}T", "AAAA-MM-DD": r"^\d{4}-\d{2}-\d{2}$", "DD/MM/AAAA": r"^\d{2}/\d{2}/\d{4}",
           "DD-MM-AAAA": r"^\d{2}-\d{2}-\d{4}", "DD.MM.AAAA": r"^\d{2}\.\d{2}\.\d{4}", "AAAA/MM/DD": r"^\d{4}/\d{2}/\d{2}", "AAAAMMDD": r"^\d{8}$"}
    s = serie.str.strip()
    for k, p in pad.items(): mostrar(f"{nome}: formato {k}", int(s.str.contains(p).sum()))
    mostrar(f"{nome}: vazia ou inválida (31/02, ano 0001...)", int(sum(limpeza.converter_data(v) is None for v in serie)))

def texto(serie, nome):
    s = serie
    mostrar(f"{nome}: acento quebrado (Ã§, Ã£...)", int(s.str.contains("Ã|Â").sum()))
    mostrar(f"{nome}: caractere invisível", int(s.str.contains("[\u200b\u200c\u200d\ufeff]").sum()))
    mostrar(f"{nome}: espaço sobrando/repetido", int((s != s.map(lambda v: " ".join(v.split()))).sum()))
    mostrar(f"{nome}: nulo disfarçado (N/A, -, 0, vazio...)", int(s.map(limpeza.eh_nulo).sum()))

if __name__ == "__main__":
    c, i, r = ler("compras"), ler("itens"), ler("resultados")
    print(f"Linhas: compras={len(c)} itens={len(i)} resultados={len(r)}")
    print("\ncompras.csv"); documento(c["cnpj_orgao"], "cnpj_orgao"); data(c["data_publicacao"], "data_publicacao")
    texto(c["razao_social_orgao"], "razao_social_orgao"); texto(c["objeto_compra"], "objeto_compra")
    mostrar("razao_social_orgao: nomes distintos no bruto", c["razao_social_orgao"].nunique())
    mostrar("razao_social_orgao: nomes distintos depois de padronizar", c["razao_social_orgao"].map(limpeza.padronizar_nome).nunique())
    mostrar("modalidade_nome: grafias distintas no bruto (7 ids)", c["modalidade_nome"].nunique())
    print("\nitens.csv"); numero(i["quantidade"], "quantidade"); numero(i["valor_unitario_estimado"], "valor_unitario_estimado")
    texto(i["descricao"], "descricao"); texto(i["material_ou_servico"], "material_ou_servico")
    mostrar("sigiloso = True", int((i["sigiloso"].str.lower() == "true").sum()))
    print("\nresultados.csv"); documento(r["ni_fornecedor"], "ni_fornecedor", r["tipo_pessoa"])
    numero(r["valor_unitario_homologado"], "valor_unitario_homologado"); numero(r["quantidade_homologada"], "quantidade_homologada")
    data(r["data_resultado"], "data_resultado"); texto(r["nome_fornecedor"], "nome_fornecedor")
    mostrar("resultados cancelados (data_cancelamento preenchida)", int((r["data_cancelamento"].str.strip() != "").sum()))
    mostrar("nome_fornecedor: nomes distintos no bruto", r["nome_fornecedor"].nunique())
    mostrar("nome_fornecedor: nomes distintos depois de padronizar", r["nome_fornecedor"].map(limpeza.padronizar_nome).nunique())
