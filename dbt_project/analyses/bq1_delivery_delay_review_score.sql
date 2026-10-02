-- Business Question: How strong is the relationship between delivery delay and review score? 

/* days_from_estimate = delivered - estimated, so negative values mean early.

Grain: 
    order_id is not unique in fact_reviews because some orders contain more than 1 review
    decided to average review_score grouped by order_id to produce 1 row per order.
    Collapses 99,224 review rows into 98,673 orders.

Bucket boundaries:
    - Cut points are rounded from the percentiles to readable values (about 2 weeks, about 1 week)
    - 0 is its own bucket and means 'on time'. The promised date is the purpose of the analysis
    - late side has 3 buckets despite holding around ~7% of orders because that's where the effect is concentrated; 
    p99 = 18 is why 'very late' starts at 15.

    From days_from_estimate, delivered orders only got:
    p25/p50/p75/p90/p95/p99 - [-17, -12, -7, -2, 3, 18]

Null values:
    There are 8 rows that have order_status = 'delivered' but have no registered delivered_customer_date_key
    those are being excluded because their delay can not be calculated without delivery date. Inspected those
    8 null values and found no common pattern.
    Note: these null values are already documented in models/schema.yml
 */
with reviews_per_order as (select
    fact_reviews.order_id
    , avg(fact_reviews.review_score) as review_score_avg
from {{ ref('fact_reviews') }} as fact_reviews
group by fact_reviews.order_id)
select
    CASE WHEN dim_o.days_from_estimate <= -15 THEN 'very early'
         WHEN dim_o.days_from_estimate BETWEEN -14 AND -6 THEN 'early'
         WHEN dim_o.days_from_estimate BETWEEN -5 AND -1 THEN 'slightly early'
         WHEN dim_o.days_from_estimate = 0 THEN 'on time'
         WHEN dim_o.days_from_estimate BETWEEN 1 AND 5 THEN 'slightly late'
         WHEN dim_o.days_from_estimate BETWEEN 6 AND 14 THEN 'late'
         WHEN dim_o.days_from_estimate >= 15 THEN 'very late' END as estimate_ranges
    , round(avg(reviews_per_order.review_score_avg),2) as avg_review_rating_score
    , count(reviews_per_order.review_score_avg) as reviewed_orders
    , count(*) as delivered_orders
    , count(*) - count(reviews_per_order.review_score_avg) as unreviewed_orders
    , round(avg(CASE WHEN reviews_per_order.review_score_avg IS NULL THEN 100.0 ELSE 0.0 END),2) AS unreviewed_percentage
from {{ ref('dim_orders') }} as dim_o
left join reviews_per_order
on dim_o.order_id = reviews_per_order.order_id
where dim_o.order_status = 'delivered' and dim_o.days_from_estimate is not null
group by estimate_ranges
order by min(dim_o.days_from_estimate)

/*
Findings:
    - 0.28 spread across the early side, very early 4.32 and on time 4.04, arriving earlier
    barely helps.
    - Score drops heavily from the promised date. Going from 'on time' to 'slightly late' costs
    about one full star (4.04 to 2.99, 1.05).
    - Score drops heavily from slightly late (1 to 5 days) to late (6 to 14 days), costs 1.24 rating.
    - Late and very late are nearly identical, late 1.75 and very late 1.73 (0.02 rating difference).
    - Missing reviews rise steadily with lateness, from 0.48% (very early) to 3.54% (very late)

- These suggest customers judge delivery against the promise date, not against absolute time; association rather than causation.
  Late orders may cluster in remote states, particular sellers, or bulky categories, any of which could lower scores on its own.
- Those 3.5% missing reviews can't change the conclusion. If the 49 unreviewed very late orders were included,
  the bucket would score between 1.70 (all 1-star) and 1.85 (all 5-star), still below on time's 4.04.
  In addition late orders are less likely to be reviewed; the reason is unknown.

  Strength (Pearson r): see bq1_delay_review_correlation.sql
*/