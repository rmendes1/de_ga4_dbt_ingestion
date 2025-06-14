{{
    config(
        materialized='table'
    )
}}

WITH all_products AS (
    SELECT DISTINCT
        item_id,
        item_name,
        item_brand,
        item_category,
        item_category2,
        item_category3
    FROM
        -- Agora lemos da nossa nova tabela de staging de itens!
        {{ ref('stg_ga4__items') }}
    WHERE item_id IS NOT NULL
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
    all_products