{{
    config(
        materialized='table'
    )
}}

-- CTE 1: Agrega os dados de evento para encontrar o início e o fim de cada sessão.
WITH session_aggregates AS (
    SELECT
        user_pseudo_id,
        ga_session_id
        ,
        -- Usamos MIN() e MAX() para definir o tempo de vida da sessão
        MIN(event_timestamp) AS session_start_timestamp_micros,
        MAX(event_timestamp) AS session_end_timestamp_micros
    FROM
        {{ ref('stg_ga4__events') }}
    WHERE ga_session_id IS NOT NULL
    GROUP BY 1, 2
),

-- CTE 2: Encontra a fonte de tráfego do primeiro evento de cada sessão.
session_traffic_source AS (
    SELECT
        user_pseudo_id,
        ga_session_id,
        traffic_source,
        traffic_medium,
        traffic_campaign
    FROM (
        -- ROW_NUMBER() para numerar os eventos dentro de cada sessão
        SELECT 
            user_pseudo_id,
            ga_session_id,
            traffic_source,
            traffic_medium,
            traffic_campaign,
            ROW_NUMBER() OVER(PARTITION BY user_pseudo_id, ga_session_id ORDER BY event_timestamp ASC) as event_row_num
        FROM {{ ref('stg_ga4__events') }}
        WHERE ga_session_id IS NOT NULL
    )
    -- Filtramos para pegar apenas o primeiro evento (a fonte de tráfego original)
    WHERE event_row_num = 1
)

-- Query final: Junta os dados agregados com os dados de atribuição de tráfego.
SELECT
    -- A chave primária é uma combinação do usuário e do ID da sessão.
    {{ dbt_utils.generate_surrogate_key(['agg.user_pseudo_id', 'agg.ga_session_id']) }} AS session_key,
    agg.user_pseudo_id,
    agg.ga_session_id,
    -- Convertendo os timestamps de microssegundos para o formato TIMESTAMP
    TIMESTAMP_MICROS(agg.session_start_timestamp_micros) as session_start_timestamp,
    TIMESTAMP_MICROS(agg.session_end_timestamp_micros) as session_end_timestamp,
    src.traffic_source,
    src.traffic_medium,
    src.traffic_campaign
FROM
    session_aggregates AS agg
LEFT JOIN
    session_traffic_source AS src
    ON agg.user_pseudo_id = src.user_pseudo_id
    AND agg.ga_session_id = src.ga_session_id