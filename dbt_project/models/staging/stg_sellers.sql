select
    --identifier
    seller_id::text as seller_id,

    --seller info
    seller_zip_code_prefix::text as seller_zip_code_prefix,
    seller_city::text as seller_city,
    seller_state::text as seller_state
from {{ source('raw_data', 'sellers') }}