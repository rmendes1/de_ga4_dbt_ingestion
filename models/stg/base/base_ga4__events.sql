{{ config(materialized='view') }}

SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    event_timestamp,
    event_name,
    user_pseudo_id,
    user_first_touch_timestamp,

    -- Campos diretos de structs
    device.category AS device_category,
    device.operating_system AS device_os,
    device.web_info.browser AS browser,
    geo.country,
    geo.continent,
    traffic_source.name AS traffic_campaign,
    traffic_source.medium AS traffic_medium,
    traffic_source.source AS traffic_source,
    ecommerce.transaction_id,
    ecommerce.purchase_revenue,
    user_ltv.revenue AS user_ltv_revenue,

    -- Deixamos os arrays para serem processados nos próximos estágios
    event_params,
    items
FROM
    {{ source('ga4_public_data', 'events') }}