select
    order_items.order_item_id,
    dim_orders.order_id,
    dim_products.product_key,
    dim_sellers.seller_key,
    dim_date.date_key as shipping_limit_date_key,
    order_items.price,
    order_items.freight_value
from {{ ref('stg_order_items')}} as order_items
left join {{ ref('dim_orders') }} as dim_orders
on order_items.order_id = dim_orders.order_id
left join {{ ref('dim_products') }} as dim_products
on order_items.product_id = dim_products.product_id
left join {{ ref('dim_sellers') }} as dim_sellers
on order_items.seller_id = dim_sellers.seller_id
left join {{ ref('dim_date') }} as dim_date
on order_items.shipping_limit_date::date = dim_date.date_day
