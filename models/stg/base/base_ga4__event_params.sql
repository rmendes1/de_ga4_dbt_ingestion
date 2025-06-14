-- Materializado como 'ephemeral', significa que ele não será criado no banco de dados.
-- Em vez disso, o dbt irá injetar o código dele como uma CTE (Common Table Expression)
-- nos modelos que o referenciam. É perfeito para modelos intermediários que não são usados sozinhos.
{{ config(materialized='ephemeral') }}

SELECT
    -- Chaves para conseguirmos juntar (JOIN) esta informação de volta ao evento original
    PARSE_DATE('%Y%m%d', event_date) as event_date,
    event_timestamp,
    user_pseudo_id,
    event_name,

    -- O conteúdo do parâmetro
    params.key,
    params.value.string_value,
    params.value.int_value,
    params.value.float_value,
    params.value.double_value
FROM
    {{ source('ga4_public_data', 'events') }},
    -- A função UNNEST que transforma o array em linhas
    UNNEST(event_params) as params