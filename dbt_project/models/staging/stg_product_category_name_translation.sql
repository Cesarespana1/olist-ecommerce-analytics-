select
    product_category_name::text as product_category_name,
    product_category_name_english::text as product_category_name_english
from {{ source('raw_data', 'product_category_name_translation') }}