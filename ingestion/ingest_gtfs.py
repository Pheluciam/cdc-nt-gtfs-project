# Load environment variables
import os
import zipfile
import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

# Create database engine
engine = create_engine(
    f"postgresql+psycopg2://{os.getenv('PGUSER')}:{os.getenv('PGPASSWORD')}"
    f"@{os.getenv('PGHOST')}:{os.getenv('PGPORT')}/{os.getenv('PGDATABASE')}"
    "?options=-csearch_path%3Dcdc_nt"
)

# Set GTFS base directory
BASE_DIR = "gtfs_data"
os.makedirs(BASE_DIR, exist_ok=True)

# Define GTFS feed files
GTFS_FEEDS = {
    "darwin": os.path.join(BASE_DIR, "google_transit_darwin.zip"),
    "alice_springs": os.path.join(BASE_DIR, "google_transit_alice_springs.zip"),
}

# Remove duplicate columns
def drop_duplicate_columns(df):
    df = df.loc[:, ~df.columns.duplicated()]
    df.columns = [c.split("__")[0] for c in df.columns]
    df = df.loc[:, ~df.columns.duplicated()]
    return df

# Extract GTFS ZIP
def extract_feed(feed_name, zip_path):
    extract_dir = os.path.join(BASE_DIR, f"extracted_{feed_name}")
    os.makedirs(extract_dir, exist_ok=True)
    with zipfile.ZipFile(zip_path, "r") as z:
        z.extractall(extract_dir)
    return extract_dir

# Build unified schemas across all feeds
def build_unified_schemas():
    unified = {}
    for feed_name, zip_path in GTFS_FEEDS.items():
        extract_dir = extract_feed(feed_name, zip_path)
        for file in os.listdir(extract_dir):
            if not file.endswith(".txt"):
                continue
            table_name = file.replace(".txt", "")
            df = pd.read_csv(os.path.join(extract_dir, file))
            df = drop_duplicate_columns(df)
            cols = set(df.columns.tolist())
            unified.setdefault(table_name, set()).update(cols)
    for table in unified:
        unified[table].add("feed_id")
    return unified

# Create tables from unified schemas
def create_tables(unified_schemas):
    with engine.begin() as conn:
        for table, cols in unified_schemas.items():
            cols_sql = ", ".join([f'"{c}" TEXT' for c in cols])
            conn.execute(text(f'CREATE TABLE IF NOT EXISTS {table} ({cols_sql});'))

# Align dataframe to unified schema
def align_df(df, table, feed_name, unified_schemas):
    df = drop_duplicate_columns(df)
    df["feed_id"] = feed_name
    target_cols = list(unified_schemas[table])
    for col in target_cols:
        if col not in df.columns:
            df[col] = None
    return df[target_cols]

# Load GTFS tables
def load_tables(unified_schemas):
    for feed_name, zip_path in GTFS_FEEDS.items():
        print(f"Loading tables for feed: {feed_name}")
        extract_dir = os.path.join(BASE_DIR, f"extracted_{feed_name}")
        for file in os.listdir(extract_dir):
            if not file.endswith(".txt"):
                continue
            table = file.replace(".txt", "")
            df = pd.read_csv(os.path.join(extract_dir, file))
            df = align_df(df, table, feed_name, unified_schemas)
            print(f"  Loading table: {table} ({len(df)} rows)")
            df.to_sql(table, engine, if_exists="append", index=False)

# Run ingestion
if __name__ == "__main__":
    print("Starting GTFS ingestion...")
    unified_schemas = build_unified_schemas()
    create_tables(unified_schemas)
    load_tables(unified_schemas)
    print("All feeds processed.")
