{{
    config(
        materialized = 'table'
    )
}}

-- Usamos uma CTE para juntar a tabela de staging com todas as dimensões
WITH events_with_dimensions AS (
    SELECT
        -- Chaves naturais do evento, que usaremos para as junções e para criar a chave primária
        stg.event_timestamp,
        stg.user_pseudo_id,
        stg.ga_session_id,
        stg.event_date,

        -- Chaves substitutas (surrogate keys) de cada dimensão
        du.user_key,
        ds.session_key,
        dg.geo_key,
        ddv.device_key,

        -- Métricas e dimensões degeneradas que virão para a tabela fato
        stg.event_name,
        stg.transaction_id,
        stg.purchase_revenue,
        stg.engagement_time_msec

    FROM
        {{ ref('stg_ga4__events') }} AS stg
    LEFT JOIN
        {{ ref('dim_dates') }} AS dd ON stg.event_date = dd.date_day
    LEFT JOIN
        {{ ref('dim_users') }} AS du ON stg.user_pseudo_id = du.user_pseudo_id
    LEFT JOIN
        {{ ref('dim_sessions') }} AS ds ON stg.ga_session_id = ds.ga_session_id AND stg.user_pseudo_id = ds.user_pseudo_id
    LEFT JOIN
        {{ ref('dim_geo') }} AS dg ON stg.continent = dg.continent AND stg.country = dg.country AND stg.region = dg.region AND stg.city = dg.city
    LEFT JOIN
        {{ ref('dim_devices') }} AS ddv ON stg.device_category = ddv.device_category AND stg.operating_system = ddv.operating_system AND stg.browser = ddv.browser AND stg.language = ddv.language
)

-- Query final que seleciona os dados e cria a chave primária da tabela fato
SELECT
    {{ dbt_utils.generate_surrogate_key(['user_pseudo_id', 'ga_session_id', 'event_timestamp', 'event_name']) }} AS event_key,
    --  Usamos a própria data como a chave para a dimensão de datas.
    event_date AS date_key,
    user_key,
    session_key,
    geo_key,
    device_key,
    event_name,
    transaction_id,
    purchase_revenue,
    engagement_time_msec,
    1 AS event_count
FROM
    events_with_dimensions