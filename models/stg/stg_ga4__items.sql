{{
    config(
        materialized='view'
    )
}}

SELECT
    -- A CHAVE NATURAL DO EVENTO
    user_pseudo_id,
    ga_session_id,
    event_timestamp,
    event_name,
    event_date,

    -- Detalhes do item, extraídos do array
    item.item_id,
    item.item_name,
    item.item_brand,
    item.item_variant,
    item.item_category,
    item.item_category2,
    item.item_category3,
    item.price_in_usd,
    item.price,
    item.quantity,
    item.item_revenue_in_usd

FROM
    {{ ref('stg_ga4__events') }},
    UNNEST(items) AS item