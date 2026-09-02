select
    orders.order_id, 
    dim_customers.customer_key, 
    orders.order_status, 
    dd_purchase.date_key as purchase_date_key, 
    dd_approved_at.date_key as approved_date_key, 
    dd_delivered_carrier_date.date_key as delivered_carrier_date_key, 
    dd_delivered_customer_date.date_key as delivered_customer_date_key, 
    dd_estimated_delivery_date.date_key as estimated_delivery_date_key, 
    orders.order_delivered_customer_date > orders.order_estimated_delivery_date as is_delayed, 
    orders.order_delivered_customer_date - orders.order_purchase_timestamp as actual_delivery_days
from {{ ref('stg_orders') }} as orders 
left join {{ ref('dim_customers') }} as dim_customers
on dim_customers.customer_id = orders.customer_id
left join {{ ref('dim_date') }} as dd_purchase
on orders.order_purchase_timestamp::date = dd_purchase.date_day
left join {{ ref('dim_date') }} as dd_approved_at
on orders.order_approved_at::date = dd_approved_at.date_day
left join {{ ref('dim_date') }} as dd_delivered_carrier_date
on orders.order_delivered_carrier_date::date = dd_delivered_carrier_date.date_day
left join {{ ref('dim_date') }} as dd_delivered_customer_date
on orders.order_delivered_customer_date::date = dd_delivered_customer_date.date_day
left join {{ ref('dim_date') }} as dd_estimated_delivery_date
on orders.order_estimated_delivery_date::date = dd_estimated_delivery_date.date_day