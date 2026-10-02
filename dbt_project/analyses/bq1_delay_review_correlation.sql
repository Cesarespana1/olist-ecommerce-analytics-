-- Business Question: How strong is the relationship between delivery delay and review score? 
/*
    corr() evaluates Pearson's r between days_from_estimate and review_score_avg per order.

    Grain: Is the same as in the bucket analysis, per-order average, delivered orders only and
    8 null excluded. See grain explanation in bq1_delivery_delay_review_score.sql

    For this query inner join is used instead of left join as only reviewed orders have a score to correlate.
*/

with reviews_per_order as (select
    fact_reviews.order_id
    , avg(fact_reviews.review_score) as review_score_avg
from {{ ref('fact_reviews') }} as fact_reviews
group by fact_reviews.order_id)
select
    corr(dim_o.days_from_estimate, reviews_per_order.review_score_avg) as correlation
    , count(*) as reviewed_orders
from {{ ref('dim_orders') }} as dim_o
inner join reviews_per_order
on dim_o.order_id = reviews_per_order.order_id
where dim_o.order_status = 'delivered' and dim_o.days_from_estimate is not null

/* 
Findings:
    - r = −0.27, r² ≈ 0.07, n = 95,824.
    - (-0.27) represent weak to moderate in linear tearms. Delay explains about 7% of the variation
    in scores along a straight line.
    - the effect isn't linear. Scores are flat across the early side and drop sharply after the promised date,
    and Pearson only measures straight-line relationships. The bucket file shows the shape.
*/