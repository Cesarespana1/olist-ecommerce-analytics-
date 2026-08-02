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

dim_geolocation (optional, only for geospatial analysis)

zip_code_prefix (PK), lat (average), lng (average), city ⚠️ Note: the same zip_code_prefix has multiple lat/lng rows in the original CSV — aggregate (average) before using it as a dimension, or joins will duplicate rows.

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
olist-ecommerce-analytics/
├── docker-compose.yml         ⬜ Pending (file exists but currently empty — postgres + pipeline services)
├── .env.example                ⬜ Pending (not yet created)
├── .gitignore
├── pipeline/
│   ├── load.py                 ⬜ Pending (currently empty — kagglehub + pandas + sqlalchemy → "raw" schema)
│   ├── pyproject.toml          ⬜ Pending (uv-managed, replaces requirements.txt)
│   ├── uv.lock                 ⬜ Pending
│   └── Dockerfile              ⬜ Pending
├── dbt_project/               ⬜ Pending initialization
│   ├── models/
│   │   ├── staging/
│   │   ├── intermediate/
│   │   └── marts/
│   ├── tests/
│   └── dbt_project.yml
├── powerbi/
│   └── dashboard.pbix         ⬜ Pending
├── screenshots/
│   └── lineage_graph.png      ⬜ Pending (dbt docs generate)
└── README.md                   ⬜ Pending (use the project description already drafted)
Current project status
 Dataset explored and columns confirmed (customer_id vs customer_unique_id, order_items grain, payments 1:N)
 Star schema designed and validated (see above)
 .gitignore written
 Postgres 15 run manually via `docker run` (not docker-compose yet, deliberately — internalizing the flags by hand before abstracting them) — confirmed booted and reachable via `docker exec ... psql`
 docker-compose.yml — NOT yet written (file exists on disk but is empty)
 .env.example — NOT yet created
 requirements.txt — being replaced by pyproject.toml + uv.lock (uv-managed), living inside pipeline/, instead of a plain requirements.txt at the repo root
 Ingestion script pipeline/load.py — folder renamed from ingestion/ to pipeline/; load.py itself is still empty, not yet written
 Next step: install uv, run `uv init` + `uv add <deps>` inside pipeline/ to generate pyproject.toml + uv.lock, write pipeline/load.py (kagglehub + pandas + sqlalchemy → "raw" schema), and test it locally with `uv run` against the manually-running Postgres container
 Then: write pipeline/Dockerfile (uv-based image), write docker-compose.yml (postgres + pipeline services, postgres healthcheck + pipeline's depends_on: service_healthy), run docker compose up -d and confirm the 9 raw tables load correctly into Postgres
 Initialize the dbt project, connect it to Postgres
 Write staging models (1 per raw table, basic cleanup)
 Write mart models (full star schema above)
 Add dbt tests (unique, not_null, relationships)
 Generate dbt docs (lineage graph) for the README
 Build the Power BI dashboard answering the 5 business questions
 Write the final README.md with the project description (already drafted, see section below) + dashboard screenshots
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

Style / preference notes
The user prefers honest, calibrated explanations (neither optimistic nor pessimistic), with step-by-step reasoning before the final answer.
Explain the "why" behind design decisions, not just the "what".
Priority: finish this project and the Call Center Analytics project (PwC/Forage) by August, with good GitHub documentation, before adding a third project.
Collaboration split: this project is meant to be ~80% the user's own hands-on work, ~20% Claude. Default to guiding (questions, concept explanations, pointing at what to look up) rather than writing implementation code (Python, SQL, dbt, Dockerfiles, compose files) — the user wants to learn this material, not just have it built. Only write code directly when explicitly asked to. Documentation/config housekeeping (like this file) is fair game to just do.