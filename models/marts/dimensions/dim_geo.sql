{{
    config(
        materialized='table'
    )
}}

-- Primeiro, usamos uma CTE para encontrar todas as combinações únicas de geolocalização
-- na nossa amostra de dados de staging.
WITH unique_locations AS (
    SELECT DISTINCT
        continent,
        country,
        region,
        city
    FROM
        {{ ref('stg_ga4__events') }}
    WHERE
        -- Adicionamos um filtro para garantir que não criaremos uma linha para dados de geo vazios
        continent IS NOT NULL AND country IS NOT NULL
)

-- A query final seleciona os dados distintos e gera a chave primária para cada combinação.
SELECT
    -- A chave primária é um hash das colunas que definem a unicidade da localização.
    {{ dbt_utils.generate_surrogate_key(['continent', 'country', 'region', 'city']) }} AS geo_key,
    continent,
    country,
    region,
    city
FROM
    unique_locations