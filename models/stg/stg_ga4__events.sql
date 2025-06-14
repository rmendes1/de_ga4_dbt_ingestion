-- CÓDIGO TEMPORÁRIO APENAS PARA A CARGA DA AMOSTRA DE DESENVOLVIMENTO
{{
    config(
        materialized='table'
    )
}}

SELECT
    -- Chaves e Timestamps
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    event_timestamp,
    event_name,
    user_pseudo_id,
    user_first_touch_timestamp,

    -- Parâmetros extraídos do array event_params
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer') AS page_referrer,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec') AS engagement_time_msec,

    -- Campos do struct de dispositivo (device)
    device.category AS device_category,
    device.operating_system AS operating_system,
    device.operating_system_version AS operating_system_version,
    device.web_info.browser AS browser,
    device.language,

    -- Campos do struct de geolocalização (geo)
    geo.continent,
    geo.country,
    geo.region,
    geo.city,

    -- Campos do struct de e-commerce
    ecommerce.transaction_id,
    ecommerce.purchase_revenue,

    -- Campos do struct de LTV do usuário
    user_ltv.revenue AS user_ltv_revenue,

    -- Campos do struct de fonte de tráfego
    traffic_source.name AS traffic_campaign,
    traffic_source.medium AS traffic_medium,
    traffic_source.source AS traffic_source,

    -- Mantemos o array de itens intacto para ser processado depois em um modelo específico para produtos.
    items
FROM
    {{ source('ga4_public_data', 'events') }}
WHERE
    -- O FILTRO CHAVE: processamos apenas os dados de um dia para nossa amostra!
    _table_suffix = '20210131'