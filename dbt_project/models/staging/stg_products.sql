select
    --identifier
    product_id::text as product_id,

    --product info
    product_category_name::text as product_category_name,
    product_name_lenght::int as product_name_length,
    product_description_lenght::int as product_description_length,
    product_photos_qty::int as product_photos_qty,
    
    --product dimensions
    --note: product_weight_g is casted to numeric(10,2) and nullif is used to filter out 0 values as it misrepresents unknown data
    nullif(product_weight_g, 0)::numeric(10,2) as product_weight_g,
    product_length_cm::numeric(10,2) as product_length_cm,
    product_height_cm::numeric(10,2) as product_height_cm,
    product_width_cm::numeric(10,2) as product_width_cm
from {{ source('raw_data', 'products')}}