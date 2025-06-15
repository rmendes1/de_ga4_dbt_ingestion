{{
    config(
        materialized='table'
    )
}}

-- CTE 1: Seleciona todos os produtos distintos, ainda com possíveis duplicatas de item_id
WITH product_entries AS (
    SELECT DISTINCT
        item_id,
        item_name,
        item_brand,
        item_category,
        item_category2,
        item_category3
    FROM
        {{ ref('stg_ga4__items') }}
    WHERE item_id IS NOT NULL
),

-- CTE 2: Usa uma função de janela para desduplicar os produtos pelo item_id
deduplicated_products AS (
    SELECT
        *,
        -- Para cada item_id, numeramos as linhas. A primeira ocorrência recebe 1, a segunda 2, etc.
        ROW_NUMBER() OVER(PARTITION BY item_id ORDER BY item_name) as row_num
    FROM
        product_entries
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['item_id']) }} AS product_key,
    item_id,
    item_name,
    item_brand,
    item_category,
    item_category2,
    item_category3
FROM
    deduplicated_products
WHERE
    row_num = 1 -- Garantimos que estamos pegando apenas uma versão de cada produto