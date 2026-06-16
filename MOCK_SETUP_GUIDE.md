# Mock Telecom Warehouse - Setup & Usage Guide

## Overview

This mock warehouse provides a local DuckDB-based environment to test and automate your SQL queries **without accessing the company database**. It includes:

- **Synthetic telecom data** for all tables (Daily Active Subs, Recharges, Loans, Voice/Data/SMS Traffic, etc.)
- **19 pre-configured SQL queries** from your workbook
- **Automatic Oracle-to-DuckDB translation** (date functions, hints, NVL→COALESCE, etc.)
- **CSV output** for each query result for easy integration testing

---

## Quick Start

### 1. Build the Mock Database (First Time Only)

```bash
python mock_warehouse.py build
```

This creates `mock_warehouse.duckdb` (~20MB) with synthetic data covering 120 days of transactions.

**Output:**
```
built mock_warehouse.duckdb
```

### 2. Run All Queries

```bash
python mock_warehouse.py run
```

This executes all 19 SQL queries and saves results to `outputs/query_NN.csv`

**Sample Output:**
```
query 01: 1 rows -> outputs/query_01.csv
query 02: 1 rows -> outputs/query_02.csv
query 03: 11 rows -> outputs/query_03.csv
...
query 19: 4 rows -> outputs/query_19.csv
```

### 3. Access Results

Each query result is saved as a CSV file:
- `outputs/query_01.csv` - Daily Active Subs
- `outputs/query_03.csv` - Daily Active Subs Regional  
- `outputs/query_09.csv` - Recharge Regional
- `outputs/query_17.csv` - Voice Regional
- etc.

Open in Excel, Pandas, or your automation tool of choice.

---

## Command Reference

### Build Options

```bash
# Build with custom database path
python mock_warehouse.py build --db my_warehouse.duckdb

# Rebuild (deletes existing and creates fresh)
python mock_warehouse.py build
```

### Run Options

```bash
# Run with defaults (mock_warehouse.duckdb, test2.sql, outputs/)
python mock_warehouse.py run

# Run with custom SQL file
python mock_warehouse.py run --sql my_queries.sql

# Run with custom output directory
python mock_warehouse.py run --out my_outputs

# Run with custom database
python mock_warehouse.py run --db my_warehouse.duckdb
```

### Combine Build & Run

```bash
# First run automatically builds if database doesn't exist
python mock_warehouse.py run
```

---

## Data Details

### Subscriber Coverage
- **240 unique MSISDNs** (phone numbers like 25190000001, 25190000002, etc.)
- **11 regions** (West Addis, East Addis, Central, South, North West, North East, East 1, East 2, West, North, Afar)
- **120 days** of synthetic transactions (from 2026-02-20 to 2026-06-19)

### Transaction Types Covered
- **Daily Active Subscribers** - VLR attachment per day
- **Recharge** - Balance top-ups (PRETUPS, CRM, etc.)
- **Loans** - Microfinance disbursements and repayments
- **Voice** - Call traffic with paid/free subscriber breakdown
- **Data** - Data traffic (MB usage)
- **SMS** - SMS traffic

### Sample Date Range
```
Base Date: 2026-05-20
Query Dates: 2026-05-19 to 2026-05-20
Lookback Period: 120 days (2026-02-20 to 2026-06-19)
```

---

## Integration Examples

### Python Automation

```python
import pandas as pd
import subprocess

# Run mock warehouse
subprocess.run(["python", "mock_warehouse.py", "run"], check=True)

# Load results
df = pd.read_csv("outputs/query_01.csv")
print(df.head())

# Automate tests
assert len(df) > 0, "Query returned no rows"
assert "count" in df.columns, "Missing expected column"
```

### PowerShell Automation

```powershell
# Build and run
python mock_warehouse.py build
python mock_warehouse.py run

# List results
Get-ChildItem outputs\query_*.csv | ForEach-Object {
    Write-Host "Processing $($_.Name)"
}
```

### CI/CD Pipeline (GitHub Actions / GitLab CI)

```yaml
- name: Run Mock Warehouse Tests
  run: |
    python mock_warehouse.py build
    python mock_warehouse.py run
    
- name: Validate Results
  run: python validate_queries.py
```

---

## Troubleshooting

### Error: "No module named 'duckdb'"

Install the dependency:
```bash
pip install duckdb
```

### Error: "Binder Error: Ambiguous reference"

This is usually handled automatically by the rewriter. If you get this:
1. Rebuild the database: `python mock_warehouse.py build`
2. Rerun: `python mock_warehouse.py run`

### Empty Query Results (0 rows)

Some queries intentionally return 0 rows due to synthetic data patterns. Check:
- `outputs/query_12.csv` and `query_13.csv` often return 0 rows (GA related queries)
- This is expected; mock data doesn't always match real-world filters

### Wrong Date Range

The mock defaults to `2026-05-19` and `2026-05-20` to match your SQL. To test different dates, edit `BASE_DATE` in `mock_warehouse.py`:

```python
BASE_DATE = date(2026, 5, 20)  # Change this to your test date
```

Then rebuild:
```bash
python mock_warehouse.py build
```

---

## Files

| File | Purpose |
|------|---------|
| `mock_warehouse.py` | Main script (build + run) |
| `test2.sql` | Your original SQL workbook (19 queries) |
| `mock_warehouse.duckdb` | Generated database (created by `build`) |
| `outputs/query_NN.csv` | Query results (created by `run`) |
| `requirements.txt` | Python dependencies |

---

## SQL Compatibility Notes

The script automatically handles:
- ✅ Oracle **hints** (`/*+ PARALLEL(32) */`) → removed
- ✅ Oracle **date functions** (`to_date()`, `to_char()`) → converted to integers (YYYYMMDD)
- ✅ Oracle **NVL** → DuckDB `COALESCE`
- ✅ Oracle **date arithmetic** (`to_date() - 29`) → pre-computed
- ✅ **Ambiguous columns** (qualified automatically)

Your SQL file stays **unchanged**; the rewriter handles translation on-the-fly.

---

## Next Steps

1. **Automate daily**: Run as a scheduled task or CI/CD job
2. **Validate results**: Compare CSV outputs against expected KPIs
3. **Scale up**: Modify `mock_warehouse.py` to add more subscribers/transactions
4. **Custom queries**: Add new queries to `test2.sql` and they'll automatically run

---

## Questions?

- Check database content: `SELECT * FROM BI.REF_SUBSCRIBER LIMIT 5;`
- Run in DuckDB CLI: `duckdb mock_warehouse.duckdb`
- Inspect script: Open `mock_warehouse.py` to adjust data generation
