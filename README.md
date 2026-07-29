This project simulates a real-world analytics engineering workflow using the Brazilian E-Commerce Public Dataset by Olist, which includes over 100,000 orders with information on customers, products, sellers, payments, reviews, and geolocation across Brazil.

The goal was to build a complete pipeline — from raw data ingestion to business-ready insights — while applying the same practices used in production data teams: containerized infrastructure, version-controlled transformations, data quality testing, and a clear separation between raw, staging, and analytics-ready layers.

Architecture:

Ingestion: Raw CSV files are loaded into a PostgreSQL database running in Docker, using a Python ingestion script.
Transformation: dbt is used to model the data through staging, intermediate, and mart layers, building a star schema (fact and dimension tables) optimized for analytical queries. Data quality tests (uniqueness, not-null, referential integrity) are included at each layer.
Analysis: Business questions are answered using SQL — including joins, CTEs, and window functions — directly on top of the dbt-built data marts.
Visualization: Key metrics and insights are presented in an interactive Power BI dashboard.

Business questions explored:

What factors are most associated with delivery delays and negative customer reviews?
Which product categories and regions drive the most revenue and repeat purchases?
How does payment method choice relate to order value and customer satisfaction?
Which sellers show the strongest performance in terms of volume, delivery time, and review scores?

Tech stack: Docker, PostgreSQL, Python, dbt, SQL, Power BI
