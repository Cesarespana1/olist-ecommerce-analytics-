select
    order_reviews.review_id,
    dim_orders.order_id,
    order_reviews.review_score,
    order_reviews.review_comment_title,
    order_reviews.review_comment_message,
    dd_review_creation_date_key.date_key as review_creation_date_key,
    dd_review_answer_date_key.date_key as review_answer_date_key
from {{ ref('stg_order_reviews' )}} as order_reviews
left join {{ ref('dim_orders') }} as dim_orders
on order_reviews.order_id = dim_orders.order_id
left join {{ ref('dim_date') }} as dd_review_creation_date_key
on dd_review_creation_date_key.date_day::date = order_reviews.review_creation_date::date
left join {{ ref('dim_date') }} as dd_review_answer_date_key
on dd_review_answer_date_key.date_day::date = order_reviews.review_answer_timestamp::date