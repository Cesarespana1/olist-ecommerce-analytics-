import os
import logging
import pandas as pd
import kagglehub
from tqdm.auto import tqdm
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

olist_dic = {
    "customers": "olist_customers_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "order_payments": "olist_order_payments_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv",
    "orders": "olist_orders_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "product_category_name_translation": "product_category_name_translation.csv"
}

def run(table_name: str, file_path: str, engine: Engine) -> None:
    """Loads CSV files into a Postgres database in chunks, targeting raw schema."""

    # Enabling iteration to load df in chunks
    df_iter = pd.read_csv(
        file_path,
        iterator=True,
        chunksize=1000
    )

    first = True # Flag to detect the first chunk
    for df_chunk in tqdm(df_iter):
        if first:
            df_chunk.head(0).to_sql(
                name=table_name,
                con=engine,
                if_exists='replace',
                schema="raw",
                index=False
            )
        first = False

        df_chunk.to_sql(
            name=table_name,
            con=engine,
            if_exists='append',
            schema="raw",
            index=False
        )

def main() -> None:
    # Loads environment info
    load_dotenv()
    db_user = os.getenv("POSTGRES_USER")
    db_password = os.getenv("POSTGRES_PASSWORD")
    db_name = os.getenv("POSTGRES_DB")
    host = os.getenv("HOST")
    port = os.getenv("PORT")

    # sqlalchemy structure to establish connection with Postgres db
    database = f"postgresql+psycopg2://{db_user}:{db_password}@{host}:{port}/{db_name}"
    engine = create_engine(database)

    # sqlalchemy connection test
    with engine.connect() as connection:
        try:
            connection.execute(text("CREATE SCHEMA IF NOT EXISTS raw;"))
            connection.commit()
        except Exception as e:
            logger.error(f"Failed to create 'raw' schema: {e}")

    # Using kagglehub library to load olist datasets
    olist_folder = kagglehub.dataset_download(
        "olistbr/brazilian-ecommerce",
        output_dir="datasets/"
        )

    # List to provide info to the user
    successful_list = []
    failed_list = []

    # Loop through each CSV and call run()
    for table_name, file_name in olist_dic.items():
        filepath = os.path.join(olist_folder, file_name)

        try:
            run(table_name, filepath, engine)
            successful_list.append(table_name)
        except Exception as e:
            logger.error(f"{table_name} failed to load: {e}")
            failed_list.append(table_name)

    logger.info(
        f"Ingested tables: {len(successful_list)}\nFailed tables: {len(failed_list)}\n"
        f"Successfully loaded: {successful_list}\nFailed to load: {failed_list}"
    )

if __name__ == "__main__":
    main()
