-- models/staging/stg_ga4__events.sql

{{
    config(
        materialized='incremental',
        partition_by={
            "field": "event_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by = ["event_name", "user_pseudo_id"]
    )
}}

-- CTE para pivotar os parâmetros de eventos, transformando linhas em colunas.
WITH event_params_pivoted AS (
    SELECT
        event_timestamp,
        user_pseudo_id,
        event_name,
        -- Usamos agregações para pivotar as linhas de parâmetros de volta para colunas
        MAX(IF(key = 'ga_session_id', value.int_value, NULL)) AS ga_session_id,
        MAX(IF(key = 'page_location', value.string_value, NULL)) AS page_location,
        MAX(IF(key = 'page_referrer', value.string_value, NULL)) AS page_referrer,
        MAX(IF(key = 'engagement_time_msec', value.int_value, NULL)) AS engagement_time_msec
    FROM
        {{ ref('base_ga4__event_params') }}
    GROUP BY 1, 2, 3
)

-- Query principal que junta os eventos base com seus parâmetros pivotados
SELECT
    base.event_date,
    base.event_timestamp,
    base.event_name,
    base.user_pseudo_id,
    base.user_first_touch_timestamp,

    -- Colunas do JOIN com os parâmetros
    params.ga_session_id,
    params.page_location,
    params.page_referrer,
    params.engagement_time_msec,

    -- Colunas que já estavam limpas no modelo base
    base.device_category,
    base.device_os,
    base.browser,
    base.country,
    base.continent,
    base.traffic_campaign,
    base.traffic_medium,
    base.traffic_source,
    base.transaction_id,
    base.purchase_revenue,
    base.user_ltv_revenue,
    base.items

FROM
    {{ ref('base_ga4__events') }} AS base
LEFT JOIN
    event_params_pivoted AS params
    -- Chave de junção para trazer os parâmetros para o evento correto
    ON base.event_timestamp = params.event_timestamp
    AND base.user_pseudo_id = params.user_pseudo_id
    AND base.event_name = params.event_name

{% if is_incremental() %}

-- A lógica incremental agora filtra o modelo base, que por sua vez lê da fonte.
-- O otimizador do BigQuery aplicará este filtro diretamente na leitura da fonte particionada.
WHERE base.event_date >= (SELECT MAX(event_date) FROM {{ this }})

{% endif %}