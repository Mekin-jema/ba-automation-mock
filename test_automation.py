#!/usr/bin/env python3
"""
Example automation script for testing SQL queries against the mock warehouse.
This demonstrates how to integrate the mock warehouse into your automation workflow.
"""

import subprocess
import sys
from pathlib import Path

import pandas as pd


def build_mock_warehouse() -> bool:
    """Build the mock database."""
    print("🔨 Building mock warehouse...")
    try:
        result = subprocess.run(
            ["python", "mock_warehouse.py", "build"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode == 0:
            print(f"✅ {result.stdout.strip()}")
            return True
        else:
            print(f"❌ Build failed: {result.stderr}")
            return False
    except subprocess.TimeoutExpired:
        print("❌ Build timed out")
        return False


def run_queries() -> bool:
    """Run all SQL queries."""
    print("\n🚀 Running SQL queries...")
    try:
        result = subprocess.run(
            ["python", "mock_warehouse.py", "run"],
            capture_output=True,
            text=True,
            timeout=60,
        )
        if result.returncode == 0:
            print(result.stdout)
            return True
        else:
            print(f"❌ Query execution failed: {result.stderr}")
            return False
    except subprocess.TimeoutExpired:
        print("❌ Query execution timed out")
        return False


def validate_results() -> bool:
    """Validate query results against expected criteria."""
    print("\n🔍 Validating results...")
    outputs_dir = Path("outputs")

    if not outputs_dir.exists():
        print("❌ outputs/ directory not found")
        return False

    csv_files = sorted(outputs_dir.glob("query_*.csv"))
    if not csv_files:
        print("❌ No query result files found")
        return False

    print(f"📊 Found {len(csv_files)} query results")

    all_valid = True
    for csv_file in csv_files:
        try:
            df = pd.read_csv(csv_file)
            rows = len(df)
            cols = len(df.columns)
            print(f"  ✓ {csv_file.name}: {rows} rows, {cols} columns")

            if rows == 0 and csv_file.name not in ["query_12.csv", "query_13.csv"]:
                print(f"    ⚠️  Warning: Empty result (expected for GA queries)")

        except Exception as e:
            print(f"  ✗ {csv_file.name}: {e}")
            all_valid = False

    return all_valid


def check_specific_metrics() -> bool:
    """Check specific business metrics from query results."""
    print("\n📈 Checking business metrics...")

    try:
        q01 = pd.read_csv("outputs/query_01.csv")
        daily_active_subs = q01.iloc[0, 0]
        print(f"  Daily Active Subscribers: {daily_active_subs}")

        if daily_active_subs <= 0:
            print("  ❌ Invalid subscriber count")
            return False

        q03 = pd.read_csv("outputs/query_03.csv")
        regional_breakdown = len(q03)
        print(f"  Regional breakdowns: {regional_breakdown}")

        q09 = pd.read_csv("outputs/query_09.csv")
        recharge_traffic = q09["TRAFFIC"].sum() if len(q09) > 0 else 0
        print(f"  Recharge traffic volume: {recharge_traffic:.2f}")

        print("  ✅ All metrics valid")
        return True

    except Exception as e:
        print(f"  ❌ Metric validation failed: {e}")
        return False


def generate_report() -> None:
    """Generate a simple report of query execution."""
    print("\n📋 Summary Report")
    print("=" * 50)

    outputs_dir = Path("outputs")
    csv_files = sorted(outputs_dir.glob("query_*.csv"))

    for idx, csv_file in enumerate(csv_files, 1):
        df = pd.read_csv(csv_file)
        print(f"Query {idx:02d}: {csv_file.name}")
        print(f"  Rows: {len(df)}, Columns: {list(df.columns)[:3]}...")

    print("=" * 50)


def main() -> int:
    """Main automation workflow."""
    print("🔬 Mock Warehouse Automation Test Suite")
    print("=" * 50)

    if not build_mock_warehouse():
        return 1

    if not run_queries():
        return 1

    if not validate_results():
        return 1

    if not check_specific_metrics():
        return 1

    generate_report()

    print("\n✅ All tests passed!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
