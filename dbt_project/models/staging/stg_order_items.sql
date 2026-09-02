select
    --identifiers
    order_id::text as order_id,
    order_item_id::int as order_item_id,
    product_id::text as product_id,
    seller_id::text as seller_id,
    
    --timestamps
    shipping_limit_date::timestamp as shipping_limit_date,

    --order info
    price::numeric(10,2) as price,
    freight_value::numeric(10,2) as freight_value
from {{source('raw_data','order_items')}}