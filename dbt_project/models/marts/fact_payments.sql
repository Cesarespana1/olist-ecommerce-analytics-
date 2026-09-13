select
    dim_orders.order_id,
    order_payments.payment_sequential,
    order_payments.payment_type,
    order_payments.payment_installments,
    order_payments.payment_value
from {{ ref('stg_order_payments') }} as order_payments
left join {{ ref('dim_orders') }} as dim_orders
on order_payments.order_id = dim_orders.order_id