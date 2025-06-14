-- Materializamos dimensões como 'table' para melhor performance de JOINs nas ferramentas de BI.
{{
    config(
        materialized='table'
    )
}}

-- Usamos uma CTE (Common Table Expression) para primeiro encontrar
-- todas as combinações únicas de atributos de dispositivo.
WITH unique_devices AS (
    SELECT DISTINCT
        device_category,
        operating_system,
        browser,
        language
    FROM
        -- Lemos da nossa tabela de staging, que é rápida e contém nossa amostra de dados.
        {{ ref('stg_ga4__events') }}
)

-- A query final seleciona os dados da CTE e adiciona a chave primária (surrogate key)
SELECT
    -- Criamos uma chave primária única e determinística para cada combinação de dispositivo.
    {{ dbt_utils.generate_surrogate_key(['device_category', 'operating_system', 'browser', 'language']) }} AS device_key,
    device_category,
    operating_system,
    browser,
    language
FROM
    unique_devices