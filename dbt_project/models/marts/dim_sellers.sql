select
    {{dbt_utils.generate_surrogate_key(['seller_id'])}} as seller_key,
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state
from {{ ref('stg_sellers')}} as s