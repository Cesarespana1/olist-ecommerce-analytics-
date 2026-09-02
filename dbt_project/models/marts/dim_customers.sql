select
    {{ dbt_utils.generate_surrogate_key(['c.customer_id']) }} as customer_key, 
    c.customer_id, 
    c.customer_unique_id,
    c.customer_zip_code_prefix, 
    c.customer_city, 
    c.customer_state
from {{ ref('stg_customers') }} as c