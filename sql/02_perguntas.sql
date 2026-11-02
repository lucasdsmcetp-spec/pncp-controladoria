USE pncp_controladoria;

-- Pergunta 1: Economia global (valor e percentual)
SELECT
    SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END)   AS estimado_comparavel,
    SUM(CASE WHEN comparavel = 1 THEN valor_total_homologado ELSE 0 END) AS homologado_comparavel,
    SUM(CASE WHEN comparavel = 1 THEN economia_valor ELSE 0 END)         AS economia_valor,
    SUM(CASE WHEN comparavel = 1 THEN economia_valor ELSE 0 END)
      / NULLIF(SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END), 0) * 100
                                                                         AS economia_pct
FROM fato_item_contratado;

-- Pergunta 2: 10 maiores fornecedores e % do volume
SELECT
    f.nome_fornecedor,
    SUM(x.valor_total_homologado) AS volume,
    SUM(x.valor_total_homologado)
      / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado) * 100 AS pct_do_total
FROM fato_item_contratado x
JOIN dim_fornecedor f ON x.sk_fornecedor = f.sk_fornecedor  
GROUP BY f.sk_fornecedor, f.nome_fornecedor                  
ORDER BY volume DESC
LIMIT 10;

-- Pergunta 2 (total): concentração dos 10 maiores
SELECT
    SUM(volume) AS volume_top10,
    SUM(volume) / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado) * 100 AS pct_top10
FROM (
    SELECT f.sk_fornecedor, SUM(x.valor_total_homologado) AS volume
    FROM fato_item_contratado x
    JOIN dim_fornecedor f ON x.sk_fornecedor = f.sk_fornecedor
    GROUP BY f.sk_fornecedor
    ORDER BY volume DESC
    LIMIT 10
) AS top10;

-- Pergunta 3: volume, participação e economia por modalidade
SELECT
    m.nome_modalidade,
    SUM(x.valor_total_homologado) AS volume,
    SUM(x.valor_total_homologado)
      / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado) * 100 AS pct_volume,
    SUM(CASE WHEN x.comparavel = 1 THEN x.economia_valor ELSE 0 END)
      / NULLIF(SUM(CASE WHEN x.comparavel = 1 THEN x.valor_total_estimado ELSE 0 END), 0) * 100 AS economia_pct
FROM fato_item_contratado x
JOIN dim_modalidade m ON x.sk_modalidade = m.sk_modalidade   
GROUP BY x.sk_modalidade, m.nome_modalidade                   
ORDER BY volume DESC;

-- Pergunta 4: ciclo médio de compras por órgão (só órgãos com 5+ itens com ciclo)
SELECT
    o.nome_orgao,
    COUNT(x.dias_ciclo) AS itens_com_ciclo,
    AVG(x.dias_ciclo)   AS ciclo_medio_dias
FROM fato_item_contratado x
JOIN dim_orgao o ON o.sk_orgao  = x.sk_orgao    
GROUP BY o.nome_orgao                  
HAVING itens_com_ciclo >= 5                    
ORDER BY ciclo_medio_dias DESC;       

-- Pergunta 5: volume, % do volume, economia e unidades compradoras por UF
SELECT
    l.regiao,
    l.uf_sigla,
    SUM(x.valor_total_homologado) AS volume,
    SUM(x.valor_total_homologado)
      / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado) * 100 AS pct_volume,
    SUM(CASE WHEN x.comparavel = 1 THEN x.economia_valor ELSE 0 END)
      / NULLIF(SUM(CASE WHEN x.comparavel = 1 THEN x.valor_total_estimado ELSE 0 END), 0) * 100 AS economia_pct,
    COUNT(DISTINCT x.sk_orgao) AS unidades_compradoras   
FROM fato_item_contratado x
JOIN dim_localidade l ON l.sk_localidade = x.sk_localidade                      
GROUP BY l.regiao, l.uf_sigla                                     
ORDER BY volume DESC;      


-- Pergunta 6: volume, % do volume, economia e ticket médio por perfil de gasto
SELECT
    perfil_gasto,
    SUM(valor_total_homologado) AS volume,
    SUM(valor_total_homologado)
      / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado) * 100 AS pct_volume,
    SUM(CASE WHEN comparavel = 1 THEN economia_valor ELSE 0 END)
  / NULLIF(SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END), 0) * 100
  AS economia_pct,
    COUNT(*) AS itens,
    SUM(valor_total_homologado) / COUNT(*) AS ticket_medio
FROM fato_item_contratado
GROUP BY perfil_gasto
ORDER BY volume DESC;
