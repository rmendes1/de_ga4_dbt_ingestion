{{
    config(
        materialized='table'
    )
}}

-- Usamos uma CTE para agregar as métricas de cada usuário
WITH user_aggregates AS (
    SELECT
        user_pseudo_id,
        -- A primeira vez que um usuário foi visto é o seu timestamp de primeiro toque
        MIN(user_first_touch_timestamp) AS first_seen_timestamp_micros,
        -- A última vez que um usuário foi visto é o timestamp do seu evento mais recente
        MAX(event_timestamp) AS last_seen_timestamp_micros,
        -- O LTV do usuário é o valor máximo registrado para ele ao longo do tempo
        MAX(user_ltv_revenue) as total_ltv_revenue
    FROM
        {{ ref('stg_ga4__events') }}
    -- Filtramos usuários nulos, se houver
    WHERE user_pseudo_id IS NOT NULL
    GROUP BY 1
)

SELECT
    -- A chave primária é gerada a partir do identificador único do usuário
    {{ dbt_utils.generate_surrogate_key(['user_pseudo_id']) }} AS user_key,
    user_pseudo_id,
    TIMESTAMP_MICROS(first_seen_timestamp_micros) AS first_seen_timestamp,
    TIMESTAMP_MICROS(last_seen_timestamp_micros) AS last_seen_timestamp,
    total_ltv_revenue
FROM
    user_aggregates