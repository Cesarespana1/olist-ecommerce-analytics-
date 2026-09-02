with date_spine as (
    {{dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2016-09-01' as date)",
        end_date="cast('2020-04-09' as date)"
    )}} )

select
    to_char(date_spine.date_day, 'YYYYMMDD')::int as date_key,
    date_spine.date_day,
    extract(year from date_spine.date_day) as year,
    extract(month from date_spine.date_day) as month,
    extract(day from date_spine.date_day) as day,
    to_char(date_spine.date_day, 'FMDay') as day_of_week
from date_spine