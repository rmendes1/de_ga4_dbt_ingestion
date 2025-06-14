{{
    config(
        materialized = 'table'
    )
}}

-- Usamos a macro do pacote dbt_date para gerar a dimensão.
-- Ela cria uma tabela com uma linha por dia entre as datas de início e fim que especificamos.
{{ dbt_date.get_date_dimension(
    start_date="2020-11-01",
    end_date="2022-02-01"
) }}