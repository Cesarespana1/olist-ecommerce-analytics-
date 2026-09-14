select
    --Note: To avoid duplicated rows on possible joins lat and lng are averaged based on zip code
    -- Note: To avoid duplicated rows on possible joins city and state are selected based on the most frequent value
    geolocation.geo_zip_code_prefix,
    mode() within group (order by geolocation.geolocation_city) as geolocation_city,
    mode() within group (order by geolocation.geolocation_state) as geolocation_state,
    AVG(geolocation.geolocation_lat) as geolocation_lat,
    AVG(geolocation.geolocation_lng) as geolocation_lng
from {{ ref('stg_geolocation') }} as geolocation
group by geo_zip_code_prefix