# Developer Guide — Implementation & Extension

This guide consolidates architecture, implementation details, code walkthroughs, extension scenarios, and troubleshooting into one place for developers.

## Contents
- Architecture overview
- Core concepts & constants
- Data model & generation
- SQL rewrite and execution pipeline
- Key functions explained
- 7 extension scenarios (copy-paste ready)
- Troubleshooting & debugging checklist
- Testing & validation steps

---

## Architecture Overview
(Adapted from IMPLEMENTATION_GUIDE.md)

High-level flow: `test2.sql` → `mock_warehouse.py` (rewriter + executor) → DuckDB → `outputs/*.csv`

Key components:
- `mock_warehouse.py` — core engine
- `test_automation.py` — validator
- `test2.sql` — 19 queries
- `mock_warehouse.duckdb` — generated DB

---

## Core Concepts & Constants
- `BASE_DATE = date(2026, 5, 20)`
- `WINDOW_DAYS = 120`
- `REGIONS` — list of 11 regions
- Dates stored as integers `YYYYMMDD`

---

## Data Model & Generation
- `Subscriber` dataclass with fields: `id_subscriber`, `msisdn`, `activation_date`, `exec_region`, `staff_flag`, `location_id`
- `build_subscribers()` → generates 240 subscribers
- `build_database()` → creates schemas, tables, inserts reference + transaction data

---

## SQL Rewriter & Execution Pipeline
- `rewrite_sql()`:
  - Remove Oracle hints (`/*+ ... */`)
  - Convert `NVL` → `COALESCE`
  - Convert `to_char(to_date('YYYYMMDD') +/- N, 'YYYYMMDD')` → integer
  - Fix ambiguous columns (qualify DS_EXEC_REGION)
- `split_statements()`:
  - Splits `test2.sql` by divider comments and semicolons
  - Returns only SELECT statements
- `run_sql()` executes each query and writes `outputs/query_NN.csv`

---

## Key Functions (Summaries)
- `day_key(date) -> int` — YYYYMMDD conversion
- `make_msisdn(index) -> str` — format msisdn
- `build_subscribers()` — generate Subscriber objects
- `build_database(db_path)` — create schemas and insert data
- `rewrite_sql(sql_text)` — convert Oracle SQL to DuckDB SQL
- `split_statements(sql_text)` — parse 19 queries
- `run_sql(db_path, sql_path, output_dir)` — execute and export

---

## 7 Extension Scenarios (Copy-paste)
1. Add more subscribers (change loop range to 1..1000)
2. Add a new transaction table (CREATE TABLE + generate rows)
3. Change `WINDOW_DAYS` for faster builds
4. Scale financial values and traffic volumes
5. Add a new column to `BI.REF_SUBSCRIBER` (customer_type)
6. Implement seasonal multipliers (weekend peaks)
7. Hybrid: load real subscribers and mock transactions

(Examples and code snippets available in the original guides)

---

## Troubleshooting & Debugging
- Add print statements in `rewrite_sql()` to inspect before/after
- Use DuckDB CLI to inspect tables: `duckdb mock_warehouse.duckdb` → `.tables`, `SELECT COUNT(*) ...`
- Common fixes: rebuild DB, correct `BASE_DATE`, adjust regex for NVL/date conversions

---

## Testing & Validation
- Run full validation: `python test_automation.py`
- Verify outputs: `ls outputs/query_*.csv` and open CSVs
- Use assertions in `test_automation.py` to check KPIs

---

## Useful Commands
```bash
# Build
python mock_warehouse.py build

# Run
python mock_warehouse.py run

# Test
python test_automation.py

# Inspect DB
duckdb mock_warehouse.duckdb
```

---

## Where to Look Next
- For beginner-level steps: `USER_GUIDE.md`
- For exact query descriptions: `SQL_OVERVIEW.txt`
- For quick code examples: `CODE_WALKTHROUGH.md`

