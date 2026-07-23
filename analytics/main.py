import argparse
import sys
import os
from sqlalchemy import create_engine, text

# Ordered list of SQL files to deploy
DEPLOYMENT_ORDER = [
    "sql/materialized_views.sql",
    "sql/analytical_views.sql",
    "sql/kpis.sql",
    "sql/executive_dashboard.sql",
    "sql/production_dashboard.sql",
    "sql/inventory_dashboard.sql",
    "sql/maintenance_dashboard.sql",
    "sql/quality_dashboard.sql",
    "sql/workforce_dashboard.sql",
    "sql/financial_dashboard.sql"
]

def deploy_sql(uri: str):
    print(f"Deploying Analytics SQL Layer to {uri}...")
    engine = create_engine(uri, isolation_level="AUTOCOMMIT")
    
    with engine.connect() as conn:
        for sql_file in DEPLOYMENT_ORDER:
            file_path = os.path.join(os.path.dirname(__file__), sql_file)
            if not os.path.exists(file_path):
                print(f"Warning: File not found {file_path}")
                continue
                
            print(f"Executing {sql_file}...")
            with open(file_path, 'r') as f:
                sql_content = f.read()
                
            try:
                conn.execute(text(sql_content))
                print(f"Successfully deployed {sql_file}")
            except Exception as e:
                print(f"Error deploying {sql_file}: {e}")
                sys.exit(1)
                
    print("Deployment Complete.")

def run_tests():
    print("Running KPI Validation Tests...")
    import pytest
    pytest.main(["tests/"])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SMAP Analytics Layer Manager")
    parser.add_argument("command", choices=["deploy", "test"], help="Action to perform")
    parser.add_argument("--db-uri", default="postgresql://postgres:postgres@localhost:5432/smap_dev", help="Database URI")
    
    args = parser.parse_args()
    
    if args.command == "deploy":
        deploy_sql(args.db_uri)
    elif args.command == "test":
        run_tests()
