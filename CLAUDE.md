Project: Olist E-Commerce Analytics Pipeline
Objective

Portfolio project for Data Analyst / Data Engineer (junior) roles. End-to-end pipeline using the public Olist (Brazilian E-Commerce) dataset, going from raw ingestion to a business dashboard, applying real practices used by production data teams: containerized infrastructure, version-controlled transformations, data quality tests, and a clear separation between layers.

Author: César Alejandro España Aragón — Computer Engineer, currently working as an Administrative Assistant, transitioning toward Data Analyst/Data Engineer roles.

Dataset
Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
9 CSV files: customers, geolocation, order_items, order_payments, order_reviews, orders, products, sellers, product_category_name_translation
An order can have multiple items, and each item can be fulfilled by a different seller.
customer_id is unique PER ORDER. customer_unique_id identifies the actual person and allows detecting repeat customers.
An order can have multiple payments (payments is 1:N relative to orders).
Reviews are generated after delivery (or after the estimated delivery date).
Tech stack
Docker Compose → PostgreSQL 15 container + a containerized pipeline service
Python (pandas, sqlalchemy) → raw ingestion script (pipeline/load.py)
uv → Python dependency management for the pipeline service (pyproject.toml + uv.lock, replacing requirements.txt), also used inside its Dockerfile to install deps
kagglehub → automated dataset download (no manual download)
dbt → transformation layer (staging → marts), with data quality tests
Power BI → final dashboard (already used at his current job)
Pipeline architecture
Olist CSVs (Kaggle, via kagglehub)
        ↓
Docker Compose → Postgres container
        ↓
Ingestion script (pipeline/load.py, containerized as its own Docker Compose service) → "raw" schema (data as-is)
        ↓
dbt:
  models/staging/      → cleanup, correct types, 1 model per raw table
  models/marts/         → final star schema (see below)
  tests/                → uniqueness, not-null, referential integrity
        ↓
Power BI (connected to dbt marts in Postgres)
Star schema (final)

Design rule applied: a number that can be summed/averaged/counted is a fact; everything else (categories, dates, descriptive identifiers) is a dimension. No fact table connects directly to another fact table — all of them go through dim_orders, which acts as a bridge dimension (this avoids the "fan-out"/row duplication problem in Power BI).

dim_customers

customer_key (PK), customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state

dim_sellers

seller_key (PK), seller_id, seller_zip_code_prefix, seller_city, seller_state

dim_products

product_key (PK), product_id, product_category_name_english (via product_category_name_translation), product_weight_g, product_length_cm, product_height_cm, product_photos_qty

dim_date

date_key (PK), full date, day, month, year, day of week

dim_geolocation (built — used for map visuals in Power BI)

geo_zip_code_prefix (PK), geolocation_city, geolocation_state, geolocation_lat (averaged), geolocation_lng (averaged) ⚠️ Note: the same zip_code_prefix has multiple rows in the original CSV, so EVERY non-key column must be aggregated or joins will duplicate rows. 19,015 distinct zip prefixes expand to 27,912 distinct (zip, city, state) combinations, because Brazilian city names appear with inconsistent accents and punctuation (zip 13318 alone has five spellings spanning two town names). Resolved with avg() for the coordinates and mode() within group for city and state — mode() picks the most frequent spelling, whereas min() would have returned a different town entirely. Result is exactly one row per zip prefix, enforced by a unique test. Joins to dim_customers / dim_sellers on their zip_code_prefix columns.

dim_orders (BRIDGE dimension — from olist_orders_dataset)

order_id (PK), customer_key (FK), order_status, purchase_date_key, approved_date_key, delivered_carrier_date_key, delivered_customer_date_key, estimated_delivery_date_key (FKs → dim_date, each in a different role), is_delayed (calculated), actual_delivery_days (calculated)

fact_order_items (grain: order item — from olist_order_items_dataset)

order_item_id (part of the grain), order_id (FK → dim_orders), product_key (FK), seller_key (FK), shipping_limit_date_key (FK → dim_date), price (fact), freight_value (fact)

fact_payments (grain: payment — from olist_order_payments_dataset)

order_id (FK → dim_orders), payment_sequential, payment_type, payment_installments, payment_value (fact)

fact_reviews (grain: review — from olist_order_reviews_dataset)

review_id (PK), order_id (FK → dim_orders), review_score (fact), review_comment_title, review_comment_message, review_creation_date_key, review_answer_date_key (FKs → dim_date)

Business questions to answer
How strong is the relationship between delivery delay (estimated vs. actual date) and review score?
Which product categories and regions generate the most revenue, and which have the worst satisfaction rates?
Are there repeat customers (using customer_unique_id), and what differentiates them from one-time buyers?
Is payment method related to order value or customer satisfaction?
Which sellers perform best combining volume, delivery time, and review scores?
Folder structure
Note: there is deliberately NO models/intermediate/ layer. The staging models are thin
enough that marts read directly from them; adding an empty layer would be cargo-culting.

olist-ecommerce-analytics/
├── docker-compose.yml          postgres (healthcheck) + pipeline (depends_on: service_healthy)
├── .gitignore
├── CLAUDE.md
├── README.md                   needs rewriting with the drafted description + screenshots
├── .env.example               ⬜ NOT created — see REMAINING in project status
├── pipeline/
│   ├── .env                    gitignored, never committed
│   ├── load.py                 chunked streaming ingestion → "raw" schema
│   ├── Dockerfile              uv-based image
│   ├── pyproject.toml          uv-managed, replaces requirements.txt
│   └── uv.lock
├── dbt_project/
│   ├── dbt_project.yml
│   ├── packages.yml            dbt_utils
│   ├── package-lock.yml
│   ├── pyproject.toml          uv-managed (this is why dbt runs as `uv run dbt`)
│   ├── uv.lock
│   ├── models/
│   │   ├── staging/            sources.yml + 9 stg_* models (1 per raw table)
│   │   │                       ⬜ no schema.yml yet — all tests currently live in marts
│   │   └── marts/              schema.yml (107 tests) + 9 models:
│   │                           dim_customers, dim_date, dim_geolocation, dim_orders,
│   │                           dim_products, dim_sellers,
│   │                           fact_order_items, fact_payments, fact_reviews
│   ├── macros/                 empty
│   ├── tests/                  empty (no singular tests; all are generic, in schema.yml)
│   └── target/                 gitignored — holds static_index.html for dbt docs
├── powerbi/
│   └── dashboard.pbix         ⬜ Pending
└── screenshots/
    └── lineage_graph.png      ⬜ Pending (current screenshot predates dim_geolocation)
Current project status
Dataset explored and columns confirmed (customer_id vs customer_unique_id, order_items grain, payments 1:N)
Star schema designed and validated (see above)
.gitignore written
docker-compose.yml written and working (postgres service with pg_isready healthcheck + pipeline service with depends_on: service_healthy)
pipeline/ uses uv (pyproject.toml + uv.lock) instead of requirements.txt, including inside its Dockerfile
pipeline/load.py written and working: chunked streaming ingestion (pd.read_csv iterator), logging, idempotent head(0)/replace then append, all 9 raw tables loaded
dbt project initialized and connected to Postgres (dbt Core 1.12.0 + dbt-postgres 1.11.0; note dbt Fusion does not support Postgres, so run dbt via `uv run dbt` from dbt_project/)
Staging models written — 9 models, 1 per raw table, with explicit type casting
Mart models written — full star schema, 9 marts (dim_customers, dim_date, dim_geolocation, dim_orders, dim_products, dim_sellers, fact_order_items, fact_payments, fact_reviews)
dbt tests written — 107 tests: 98 pass, 9 documented warnings, 0 errors
dbt docs generated (lineage graph viewable via target/static_index.html; port forwarding in Codespaces is unreliable, download the static file and open it locally)
REMAINING: staging schema.yml (all tests currently live in marts; a staging failure should say WHERE it broke, and the product_category_name not_null test belongs there)
REMAINING: regenerate the lineage graph screenshot into screenshots/lineage_graph.png (the current one predates dim_geolocation)
REMAINING: 3 dbt deprecation warnings (combination_of_columns needs nesting under `arguments:`) and dim_date's description has its date range reversed
REMAINING: Power BI dashboard answering the 5 business questions
REMAINING: final README.md (description already drafted below + lineage graph + dashboard screenshots)
REMAINING: .env.example is missing. pipeline/.env is correctly gitignored, but someone cloning this repo has no way to know which variables to set. Needs POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, HOST, PORT, KAGGLE_API_TOKEN with placeholder values. Cheap to add and reviewers notice its absence.
REMAINING: rotate the Kaggle API token. It was printed into a session transcript while reading pipeline/.env. It was never committed (verified with git log --all -- pipeline/.env), so this is precautionary rather than urgent.

dbt operational notes (learned the hard way — not derivable from the code)

Run dbt as `uv run dbt` from inside dbt_project/. A bare `dbt` resolves to dbt Fusion 2.0, which refuses Postgres outright ("the 'postgres' adapter is not yet supported by dbt Fusion"). This also blocks the official dbt VS Code extension.

Views cascade-drop. Every model is materialized as a view, so rebuilding an upstream model DROPS all of its downstream views. Rebuilding dim_date silently destroyed all three fact tables — twice. Always rebuild descendants with `dbt run --select <model>+` (the trailing + means "and everything downstream").

`dbt build` stops downstream work when a test errors. One failing dim_orders test produced SKIP=34, so the fact models never got rebuilt. Combined with the cascade-drop above, this leaves fact views MISSING from the database while the run output still looks mostly fine. If tests suddenly fail with "relation does not exist", this is why — re-run the models, don't debug the tests.

A malformed test definition fails SILENTLY. A data_tests: block written as a YAML mapping instead of a list was discarded with no error and no warning — the tests simply did not exist. `dbt ls --resource-type test --select <model>` is the only reliable way to confirm a test is real. Always run it after adding tests.

Postgres connection details (non-obvious): container olist_ecommerce_project-postgres-1, user `root` (NOT postgres), database `olist-ecommerce` (contains a hyphen, so it needs quoting in SQL), schemas `raw` (ingested tables) and `analytics` (all dbt models). Start it with `docker compose up -d postgres` — the Codespace does not keep it running between sessions.

dbt docs in Codespaces: port forwarding is unreliable and repeatedly failed (both `dbt docs serve` and a plain python http.server). Use `dbt docs generate --static`, then DOWNLOAD target/static_index.html and open it locally in a real browser. Opening it inside VS Code renders a blank page because scripts are sandboxed there. Also note `dbt docs serve` throws a traceback on Ctrl+C — that is normal, not an error.

Power BI connectivity — decide before starting the dashboard
Postgres runs inside the Codespace; Power BI Desktop runs on a local Windows machine and cannot reach it. Three options: (1) run the same docker-compose stack locally with Docker Desktop — cleanest, keeps the live-warehouse-connection story intact; (2) forward port 5432 publicly from the Codespace — works but exposes a database to the internet; (3) export the marts to CSV/Parquet — simplest but loses the "BI tool connected to a warehouse" narrative.

Project description (for README, already drafted)

Short description:

End-to-end data pipeline and analytics project using the Brazilian E-Commerce (Olist) dataset — from raw ingestion to a dimensional model built with dbt, queried with SQL, and visualized in Power BI.

Full description:

This project simulates a real-world analytics engineering workflow using the Brazilian E-Commerce Public Dataset by Olist, which includes over 100,000 orders with information on customers, products, sellers, payments, reviews, and geolocation across Brazil.

The goal was to build a complete pipeline — from raw data ingestion to business-ready insights — while applying the same practices used in production data teams: containerized infrastructure, version-controlled transformations, data quality testing, and a clear separation between raw, staging, and analytics-ready layers.

Architecture:

Ingestion: Raw CSV files are loaded into a PostgreSQL database running in Docker, using a Python ingestion script.
Transformation: dbt is used to model the data through staging, intermediate, and mart layers, building a star schema (fact and dimension tables) optimized for analytical queries. Data quality tests (uniqueness, not-null, referential integrity) are included at each layer.
Analysis: Business questions are answered using SQL — including joins, CTEs, and window functions — directly on top of the dbt-built data marts.
Visualization: Key metrics and insights are presented in an interactive Power BI dashboard.

Tech stack: Docker, PostgreSQL, Python, dbt, SQL, Power BI

Portfolio talking points (for the README)

Findings from actually investigating test failures instead of silencing them. Keep the concrete numbers — they are what make these credible.

Anomaly investigation: 14 orders marked delivered with no approval timestamp
All 14 have payment records totalling R$1,954.60, so the approval event definitely happened and only the timestamp is missing. Conclusion: a source-system logging gap affecting 0.015% of 96,478 delivered orders, not a business-process problem.
Method point worth telling: review scores were considered as evidence and rejected. There is no causal path from "a timestamp failed to write" to "the customer liked the product", so review scores cannot discriminate between the hypotheses; payment records can.
Baseline discipline: those 14 orders average 4.36 review score, which only means something next to the 4.16 population average. Their average was above baseline while their 5-star share (57.1%) was below it (59.2%) — metrics pointing in opposite directions is the signature of small-sample noise (n=14, SE about +/-0.37).

review_id is not a primary key: 789 duplicates
The same review_id appears on 2-3 different order_ids with the same score — one review covering several orders.
Real grain is (review_id, order_id), enforced with dbt_utils.unique_combination_of_columns.
Matters for business question 1: naively averaging review_score double-counts these rows.

Silent placeholder data: 4 products with weight 0 g
All bed_bath_table, identical 30x25 dimensions, and actually sold 8 times, so they are not unused rows.
A weight of 0 g is physically impossible, so it is placeholder data rather than a measurement — and not_null cannot see it. Fixed with nullif(product_weight_g, 0) in staging plus dbt_utils.accepted_range.
Deliberate contrast: 9 payments of R$0.00 (6 voucher, 3 not_defined) were kept as valid, because zero is unusual there but not impossible.

Silent row loss: an inner join dropped 623 products
dim_products originally inner-joined the category translation table, cutting 32,951 products to 32,328 and silently orphaning 1,627 fact rows.
Root cause: 610 source NULLs plus 13 products in two categories absent from the translation table (portateis_cozinha_e_preparadores_de_alimentos, pc_gamer).
Fixed with a left join and a three-argument coalesce falling back to the Portuguese name, then 'unknown category'. Verified 112,650/112,650 fact rows match.

Join fan-out prevented in dim_geolocation
19,015 distinct zip prefixes but 27,912 distinct (zip, city, state) combinations, because Brazilian city names appear with inconsistent accents and punctuation — zip 13318 alone has five spellings spanning two town names.
Collapsed to exactly one row per zip: avg() for coordinates, mode() within group for city and state. mode() picks the most frequent spelling; min() would have returned a different town entirely.

A dimension coverage gap caught by a test
A shipping_limit_date of 2020-04-09 fell one day past dim_date's upper bound, producing 2 null date keys. Found by a not_null test, not by inspection.

Testing practices worth explaining
unique belongs only on grain keys. Four early tests put unique on fact-table foreign keys, which asserts the opposite of a star schema (a product could only ever be sold once). Fact grains need composite tests instead.
Scoping separates "missing" from "not applicable": where: "order_status = 'delivered'" takes 1,783 null carrier dates down to 2, because an unavailable order was never handed to a carrier.
error_if thresholds turn known anomalies into regression guards ("8 is the baseline, alert if it exceeds 10"), which is a different statement from severity: warn ("never block, at any volume").
Beware hollow greens: a not_null test on a column that a coalesce already backfills always passes and asserts nothing. That test belongs upstream in staging.
Malformed test definitions fail silently. A data_tests: block written as a mapping instead of a list was discarded with no error and no warning — the tests simply did not exist. dbt ls --resource-type test --select <model> is the only way to confirm a test is real.

Design decisions to explain
dim_orders is a bridge dimension: no fact table joins another fact table, everything routes through it. This is what prevents row-duplication fan-out in Power BI, and it is visible in the lineage graph.
customer_id is unique per order while customer_unique_id identifies the person. The grain choice is deliberate and documented because it affects all repeat-customer analysis.
dim_date has no upstream source because it is generated with dbt_utils.date_spine — expected for a date dimension, but worth being ready to explain.
The 9 remaining test warnings are documented source-data gaps, each investigated, not thresholds set to make red disappear.

Final test suite: 107 tests, 98 pass, 9 documented warnings, 0 errors.

Style / preference notes
The user prefers honest, calibrated explanations (neither optimistic nor pessimistic), with step-by-step reasoning before the final answer.
Explain the "why" behind design decisions, not just the "what".
Priority: finish this project and the Call Center Analytics project (PwC/Forage) by August, with good GitHub documentation, before adding a third project.
Collaboration split: this project is meant to be ~80% the user's own hands-on work, ~20% Claude. Default to guiding (questions, concept explanations, pointing at what to look up) rather than writing implementation code (Python, SQL, dbt, Dockerfiles, compose files) — the user wants to learn this material, not just have it built. Only write code directly when explicitly asked to. Documentation/config housekeeping (like this file) is fair game to just do.