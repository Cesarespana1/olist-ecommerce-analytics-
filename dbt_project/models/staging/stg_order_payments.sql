select
    --identifier
    order_id::text as order_id,

    --payment info
    payment_sequential::int as payment_sequential,
    payment_type::text as payment_type,
    payment_value::numeric(10,2) as payment_value,
    payment_installments::int as payment_installments
from {{ source('raw_data', 'order_payments') }}