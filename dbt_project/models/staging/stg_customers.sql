select
    --idientifiers
    customer_id::text as customer_id,
    customer_unique_id::text as customer_unique_id,

    --geolocation info
    customer_zip_code_prefix::text as customer_zip_code_prefix,
    customer_city::text as customer_city,
    customer_state::text as customer_state
from {{ source('raw_data', 'customers') }}