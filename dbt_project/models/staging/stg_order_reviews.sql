select 
    --identifiers
    review_id::text as review_id,
    order_id::text as order_id,

    --timestamps
    review_creation_date::timestamp as review_creation_date,
    review_answer_timestamp::timestamp as review_answer_timestamp,

    --review info
    review_score::int as review_score,
    review_comment_title::text as review_comment_title,
    review_comment_message::text as review_comment_message
from {{ source('raw_data', 'order_reviews') }}