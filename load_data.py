"""Load the UCI "Default of Credit Card Clients" CSV into a PostgreSQL database.

Setup (once):
    pip install pandas sqlalchemy psycopg2-binary
    Create an empty database, e.g. in pgAdmin or:  createdb creditdb

Usage:
    python load_data.py UCI_Credit_Card.csv
    python load_data.py UCI_Credit_Card.csv postgresql://postgres:YOUR_PASSWORD@localhost:5432/creditdb

If you don't pass a connection URL, the script uses the DATABASE_URL environment variable,
and if that is not set either it uses:
    postgresql://postgres:postgres@localhost:5432/creditdb

Creates three tables:
  - credit_default      : cleaned customer table (one row per customer)
  - education_lookup    : education code -> label
  - marriage_lookup     : marriage code -> label
"""
import os
import sys

import pandas as pd
from sqlalchemy import create_engine, text

DEFAULT_URL = "postgresql://postgres:postgres@localhost:5432/creditdb"


def clean_columns(df: pd.DataFrame) -> pd.DataFrame:
    # lower-case, replace spaces/dots with underscores
    df.columns = [c.strip().lower().replace(" ", "_").replace(".", "_") for c in df.columns]
    # the dataset calls the latest repayment status PAY_0 (there is no PAY_1); rename for clarity
    df = df.rename(columns={
        "pay_0": "pay_1",
        "default_payment_next_month": "default_next_month",
    })
    # some versions of the file use X1..X23 headers; fail early with a clear message
    if "limit_bal" not in df.columns:
        raise SystemExit(
            "Column 'LIMIT_BAL' not found. Use the Kaggle file UCI_Credit_Card.csv "
            "(or the UCI .xls saved as CSV with the header row on line 1)."
        )
    return df


def main(csv_path: str, url: str) -> None:
    df = pd.read_csv(csv_path)
    df = clean_columns(df)

    # --- basic validation ---
    print(f"Rows loaded: {len(df):,}")
    print("Null values in the file (should be 0):", int(df.isna().sum().sum()))
    print("Duplicate IDs:", int(df.duplicated(subset=["id"]).sum()) if "id" in df.columns else "n/a")

    # always use the psycopg2 driver (installed by: pip install psycopg2-binary)
    if url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+psycopg2://", 1)
    engine = create_engine(url)

    # --- small lookup tables (used in the JOIN query) ---
    # In the raw data: 1=graduate school, 2=university, 3=high school, 0/4/5/6 = other/unknown
    edu = pd.DataFrame({
        "education": [0, 1, 2, 3, 4, 5, 6],
        "education_label": ["Other", "Graduate school", "University", "High school",
                            "Other", "Other", "Other"],
    })
    mar = pd.DataFrame({
        "marriage": [0, 1, 2, 3],
        "marriage_label": ["Other", "Married", "Single", "Other"],
    })

    with engine.begin() as con:
        df.to_sql("credit_default", con, if_exists="replace", index=False)
        edu.to_sql("education_lookup", con, if_exists="replace", index=False)
        mar.to_sql("marriage_lookup", con, if_exists="replace", index=False)
        count = con.execute(text("SELECT COUNT(*) FROM credit_default")).scalar()

    print(f"Done. {count:,} rows are now in the credit_default table.")


if __name__ == "__main__":
    if len(sys.argv) not in (2, 3):
        raise SystemExit("Usage: python load_data.py <path-to-csv> [postgresql-url]")
    db_url = sys.argv[2] if len(sys.argv) == 3 else os.environ.get("DATABASE_URL", DEFAULT_URL)
    main(sys.argv[1], db_url)
