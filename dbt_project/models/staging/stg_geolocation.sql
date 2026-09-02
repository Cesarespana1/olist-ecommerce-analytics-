select
    geolocation_zip_code_prefix::text as geo_zip_code_prefix,
    geolocation_lat::numeric(9,6) as geolocation_lat,
    geolocation_lng::numeric(9,6) as geolocation_lng,
    geolocation_city::text as geolocation_city,
    geolocation_state::text as geolocation_state
from {{ source('raw_data', 'geolocation') }}