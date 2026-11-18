
import os
import pandas as pd
from pathlib import Path
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

# Database configuration
connection_url = URL.create(
    drivername="postgresql+psycopg2",
    username=os.getenv("DB_USER", "postgres"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST", "localhost"),
    port=int(os.getenv("DB_PORT", "5432")),
    database="hotel_analytics"
)

engine = create_engine(connection_url)

DATA_DIR = Path("data/raw")

TABLES = [
    "hotels",
    "rooms",
    "guests",
    "employees",
    "reservations",
    "stays",
    "room_nights",
    "guest_feedback",
    "employee_history"
]


def load_data():

    print("Starting PostgreSQL data loading...")
    print("=" * 55)

    with engine.begin() as connection:

        # Prevent accidental duplicate loading.
        for table in TABLES:
            count = connection.execute(
                text(f'SELECT COUNT(*) FROM "{table}"')
            ).scalar()

            if count != 0:
                raise ValueError(
                    f"Table {table} is not empty. "
                    "Resolve existing records before loading."
                )

        for table in TABLES:

            file_path = DATA_DIR / f"{table}.csv"

            print(f"\nLoading {table}...")

            df = pd.read_csv(file_path)

            df.to_sql(
                name=table,
                con=connection,
                if_exists="append",
                index=False,
                chunksize=5000,
                method=None
            )

            db_count = connection.execute(
                text(f'SELECT COUNT(*) FROM "{table}"')
            ).scalar()

            print("CSV records:", len(df))
            print("Database records:", db_count)

            if db_count != len(df):
                raise ValueError(
                    f"Record count mismatch in {table}"
                )

    print("\n" + "=" * 55)
    print("ALL DATASETS LOADED SUCCESSFULLY")


if __name__ == "__main__":
    load_data()
