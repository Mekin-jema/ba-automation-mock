# Mock Telecom Warehouse - Implementation Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Core Concepts](#core-concepts)
3. [Implementation Details](#implementation-details)
4. [Step-by-Step Execution Flow](#step-by-step-execution-flow)
5. [How to Extend & Add Features](#how-to-extend--add-features)
6. [Troubleshooting & Debugging](#troubleshooting--debugging)

---

## Architecture Overview

### High-Level Design

```
┌─────────────────────────────────────────────────────────┐
│                  Your Test Environment                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  test2.sql  ──────┐                                    │
│  (19 queries)     │                                    │
│                   │                                    │
│                   ├──→ mock_warehouse.py ──→ DuckDB   │
│                   │    (Rewriter +        Database    │
│  requirements.txt ┤     Executor)         (~2.6 MB)   │
│                   │                           │        │
│  test_automation. ┤                           │        │
│  py               ├──────────────────────────┘        │
│  (Validator)      │                                    │
│                   ├─→ outputs/query_NN.csv (19 files) │
│                   │    ↓                              │
│                   └─→ Your Automation Scripts         │
│                                                       │
└─────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Purpose | Type |
|-----------|---------|------|
| `mock_warehouse.py` | Database builder + SQL executor | Core |
| `mock_warehouse.duckdb` | Local embedded database | Data Store |
| `test2.sql` | 19 Oracle SQL queries | Input |
| `test_automation.py` | Testing framework | Validator |
| `outputs/` | Query result CSVs | Output |

---

## Core Concepts

### 1. DuckDB vs Oracle

**Why DuckDB?**
- ✅ **Embedded** - No server needed, runs locally
- ✅ **Fast** - In-memory SQL engine
- ✅ **SQL Compatible** - Supports most SQL syntax
- ✅ **CSV Native** - Exports directly to CSV
- ✅ **Lightweight** - 100MB total, no installation

**Conversion Needed:**
```
Oracle SQL              →  DuckDB SQL
────────────────────────────────────────
/*+ PARALLEL(32) */         → (removed)
NVL(x, y)                   → COALESCE(x, y)
to_date('20260520','YYYYMMDD') → 20260520
to_char(..., 'YYYYMMDD')    → as integer
```

### 2. Mock Data Strategy

**Subscriber Generation (240 MSISDNs):**
```python
for index in range(1, 241):
    msisdn = f"2519{index:08d}"  # 25190000001, 25190000002, ...
    region = REGIONS[(index-1) % 11]  # Distribute across regions
    activation_date = random past date
    staff_flag = 1 if index % 17 == 0 else 0
```

**Date Generation (120 days):**
```python
BASE_DATE = 2026-05-20  # Your test date
WINDOW_DAYS = 120       # Historical depth

# Generates: 2026-02-20 through 2026-06-19
report_days = [BASE_DATE - 120 days, ..., BASE_DATE]
```

**Transaction Generation:**
- For each day, simulate realistic activities
- Multiple transactions per subscriber
- Realistic financial values (1K - 50K Birr)
- Various account types, bundle types, etc.

### 3. SQL Query Pipeline

```
Raw SQL (test2.sql)
      ↓
┌─────────────────────────┐
│ SQL Rewriter            │
│ - Remove hints          │
│ - Convert dates         │
│ - Fix ambiguous columns │
└─────────────────────────┘
      ↓
DuckDB-Compatible SQL
      ↓
┌─────────────────────────┐
│ Query Splitter          │
│ - Identify boundaries   │
│ - Extract each query    │
│ - Skip comments         │
└─────────────────────────┘
      ↓
List of 19 SELECT Statements
      ↓
┌─────────────────────────┐
│ DuckDB Executor         │
│ - Execute each query    │
│ - Fetch results         │
│ - Export to CSV         │
└─────────────────────────┘
      ↓
outputs/query_01.csv through query_19.csv
```

---

## Implementation Details

### Part 1: Imports & Configuration

```python
from __future__ import annotations

import argparse              # Command-line arguments
import csv                  # CSV file writing
import re                   # Regular expressions (pattern matching)
from dataclasses import dataclass  # Type-safe data containers
from datetime import date, datetime, timedelta  # Date arithmetic
from pathlib import Path    # File path handling
from typing import Iterable  # Type hints

import duckdb              # Embedded SQL database
```

**Why each import?**
- `dataclass` - Type-safe Subscriber objects
- `re` - Parse and transform SQL patterns
- `duckdb` - Execute SQL, manage database
- `csv` - Write results to files

### Part 2: Constants

```python
BASE_DATE = date(2026, 5, 20)  # Must match your test2.sql dates (20260520)

WINDOW_DAYS = 120  # How far back to generate data
               # 120 days = ~4 months of history
               # You'll query: 2026-02-20 to 2026-06-19
               # Queries typically ask for 30/90 day windows

REGIONS = [
    "West Addis",   # Index 0
    "East Addis",   # Index 1
    "Central",      # Index 2
    # ... etc (11 regions matching your company)
]
```

**Purpose:**
- `BASE_DATE` anchors all generated dates
- `WINDOW_DAYS` controls data volume
- `REGIONS` matches your real region list (must match!)

### Part 3: Data Model

```python
@dataclass(frozen=True)  # Immutable, hashable
class Subscriber:
    id_subscriber: int      # 1-240
    msisdn: str            # "25190000001"
    activation_date: int   # 20260101 (yyyymmdd)
    exec_region: str       # "West Addis"
    staff_flag: int        # 0 or 1
    location_id: int       # 1-11 (region ID)
```

**Why dataclass?**
- Type-safe, no typos
- Hashable (can use in sets/dicts)
- Frozen = immutable (safe to pass around)
- Auto-generates `__init__`, `__repr__`, etc.

### Part 4: Helper Functions

```python
def day_key(value: date) -> int:
    """Convert date to YYYYMMDD integer.
    
    Example:
        day_key(date(2026, 5, 20)) → 20260520
    """
    return int(value.strftime("%Y%m%d"))


def make_msisdn(index: int) -> str:
    """Generate phone number from index.
    
    Example:
        make_msisdn(1) → "25190000001"
        make_msisdn(42) → "25190000042"
    
    Why format this way?
    - 2519 = Ethiopia country code + operator prefix
    - Pads to 8 digits so indexing stays consistent
    """
    return f"2519{index:08d}"


def date_range(start: date, days: int) -> Iterable[date]:
    """Generate sequence of dates.
    
    Example:
        list(date_range(date(2026,1,1), 3))
        → [2026-01-01, 2026-01-02, 2026-01-03]
    """
    for offset in range(days):
        yield start + timedelta(days=offset)
```

### Part 5: Subscriber Generation

```python
def build_subscribers() -> list[Subscriber]:
    """Generate 240 mock subscribers with realistic distribution.
    
    Logic:
    1. Create 240 subscribers (index 1-240)
    2. Distribute across 11 regions (round-robin)
    3. Assign random activation dates (past 40-120 days)
    4. Mark every 17th as staff (staff_flag=1)
    
    Output:
        [
            Subscriber(id=1, msisdn="25190000001", region="West Addis", ...),
            Subscriber(id=2, msisdn="25190000002", region="East Addis", ...),
            ...
            Subscriber(id=240, msisdn="25190000240", region="North", ...),
        ]
    """
    subscribers: list[Subscriber] = []
    for index in range(1, 241):
        region = REGIONS[(index - 1) % len(REGIONS)]
        # (index-1) % 11 gives us: 0,1,2,...,10,0,1,2,...
        # Cycles through regions evenly
        
        location_id = (index - 1) % len(REGIONS) + 1
        # Same logic, but +1 to get 1-11 instead of 0-10
        
        activation_date = day_key(
            BASE_DATE - timedelta(days=40 + (index % 80))
        )
        # Activations spread over 80-120 days ago
        
        staff_flag = 1 if index % 17 == 0 else 0
        # Every 17th subscriber (roughly 7%) is staff
        
        subscribers.append(
            Subscriber(
                id_subscriber=index,
                msisdn=make_msisdn(index),
                activation_date=activation_date,
                exec_region=region,
                staff_flag=staff_flag,
                location_id=location_id,
            )
        )
    return subscribers
```

### Part 6: Database Building - Schema

```python
def build_database(db_path: Path) -> None:
    """Build the complete mock database."""
    
    # Delete old database if exists (fresh start)
    if db_path.exists():
        db_path.unlink()

    subscribers = build_subscribers()  # 240 subscribers
    report_start = BASE_DATE - timedelta(days=WINDOW_DAYS - 1)
    report_days = [day for day in date_range(report_start, WINDOW_DAYS)]
    
    with duckdb.connect(str(db_path)) as con:
        # Create schemas (like Oracle schemas)
        con.execute("CREATE SCHEMA IF NOT EXISTS BI")
        con.execute("CREATE SCHEMA IF NOT EXISTS TIGIST_KEBEDE")
        
        # Create all tables that your SQL queries expect
        con.execute("""
            CREATE TABLE TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS (
                msisdn VARCHAR,           -- Phone number
                id_date INTEGER,          -- Date as 20260520
                service_type VARCHAR      -- "B.DATA", "B.VOICE_INC_ONNET"
            )
        """)
        
        con.execute("""
            CREATE TABLE BI.REF_LOCATION (
                id_location INTEGER,      -- 1-11 (region ID)
                ds_exec_region VARCHAR    -- "West Addis", etc.
            )
        """)
        
        # ... create remaining 8 tables
```

### Part 7: Database Building - Data Insertion

```python
# Insert reference data (regions)
con.executemany(
    "INSERT INTO BI.REF_LOCATION VALUES (?, ?)",
    [(index + 1, region) for index, region in enumerate(REGIONS)]
)
# Inserts: (1, "West Addis"), (2, "East Addis"), ..., (11, "Afar")

# Insert subscribers
con.executemany(
    "INSERT INTO BI.REF_SUBSCRIBER VALUES (?, ?, ?, ?, ?)",
    [
        (
            sub.id_subscriber,
            sub.msisdn,
            sub.activation_date,
            sub.exec_region,
            sub.staff_flag,
        )
        for sub in subscribers
    ]
)

# Generate & insert transaction data
daily_rows = []
for day_index, current_day in enumerate(report_days):
    key = day_key(current_day)
    for offset in range(14):  # 14 activity records per day
        subscriber = subscribers[(day_index * 7 + offset) % len(subscribers)]
        service_type = (
            "B.VOICE_INC_ONNET" 
            if (day_index + offset) % 19 == 0 
            else "B.DATA"
        )
        daily_rows.append((subscriber.msisdn, key, service_type))

con.executemany(
    "INSERT INTO TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS VALUES (?, ?, ?)",
    daily_rows
)
```

---

## Step-by-Step Execution Flow

### Flow 1: `python mock_warehouse.py build`

```
START
  ↓
parse_args() → args.command = "build"
  ↓
db_path = Path("mock_warehouse.duckdb")
  ↓
build_database(db_path)
  │
  ├─ Delete old database if exists
  │
  ├─ build_subscribers() → 240 Subscriber objects
  │
  ├─ Connect to DuckDB
  │
  ├─ CREATE SCHEMA BI, TIGIST_KEBEDE
  │
  ├─ CREATE 10 tables:
  │  - MW_DAILY_ACTIVE_SUBS
  │  - REF_LOCATION
  │  - REF_SUBSCRIBER
  │  - FCT_SUBSCRIBER_ACTIVATION
  │  - REF_ACCOUNT
  │  - REF_PRODUCT
  │  - FCT_FIN_BLNC_MVMN (Financial)
  │  - FCT_TRAFFIC (Voice/Data/SMS)
  │  - etc.
  │
  ├─ INSERT reference data:
  │  - 11 regions
  │  - 240 subscribers
  │  - Account types
  │  - Product types
  │
  ├─ Generate transaction data:
  │  - 120 days × 14 records/day = 1,680 daily active records
  │  - 2 dates × 4 traffic types × 14 = 112 financial transaction records
  │  - 2 dates × 7 traffic types × 2 = 28 traffic records
  │
  └─ Close connection
  ↓
print("built mock_warehouse.duckdb")
  ↓
END
```

**Result:** `mock_warehouse.duckdb` (~2.6 MB) with all tables populated

### Flow 2: `python mock_warehouse.py run`

```
START
  ↓
parse_args() → args.command = "run"
  ↓
db_path = "mock_warehouse.duckdb"
  ↓
if not db_path.exists(): build_database()  ← Automatic rebuild
  ↓
run_sql(db_path, Path("test2.sql"), Path("outputs"))
  │
  ├─ Read test2.sql (entire file)
  │
  ├─ rewrite_sql(sql_text)
  │  │
  │  ├─ Remove all Oracle hints: /*+ PARALLEL(32) */ → ""
  │  │
  │  ├─ Convert NVL to COALESCE:
  │  │    NVL(col, 0) → COALESCE(col, 0)
  │  │
  │  ├─ Convert date expressions:
  │  │    to_char(to_date('20260520','YYYYMMDD') - 29, 'YYYYMMDD')
  │  │    → 20260491  (computed value)
  │  │
  │  ├─ Fix ambiguous columns:
  │  │    WHEN DS_EXEC_REGION = '...'
  │  │    → WHEN b.DS_EXEC_REGION = '...'
  │  │
  │  └─ Output: DuckDB-compatible SQL
  │
  ├─ split_statements(sql_text)
  │  │
  │  ├─ Split by divider comments: ----SECTION----
  │  │
  │  ├─ Skip non-SELECT (comments, empty lines)
  │  │
  │  └─ Output: 19 individual SELECT statements
  │
  ├─ Connect to DuckDB
  │
  ├─ For each of 19 statements:
  │  │
  │  ├─ Execute: con.execute(statement)
  │  │
  │  ├─ Fetch results: cursor.fetchall()
  │  │
  │  ├─ Get column names: cursor.description
  │  │
  │  ├─ Write CSV:
  │  │    - Header row: column names
  │  │    - Data rows: result tuples
  │  │
  │  ├─ Save to: outputs/query_NN.csv
  │  │
  │  └─ Print: "query NN: XX rows -> outputs/query_NN.csv"
  │
  └─ Close connection
  ↓
END
```

**Result:** 19 CSV files in `outputs/`
- `query_01.csv`: Daily Active Subs
- `query_03.csv`: Daily Active Subs Regional
- ... etc

---

## How to Extend & Add Features

### Scenario 1: Add More Subscribers

**Current:** 240 subscribers
**Goal:** 1,000 subscribers

**Step 1: Update constant**
```python
# In build_subscribers()
for index in range(1, 1001):  # Change from 241 to 1001
    # Rest of code unchanged
```

**Step 2: Rebuild**
```bash
python mock_warehouse.py build
```

**Why it works:**
- All other code uses `len(REGIONS)` and modulo arithmetic
- Automatically distributes across regions
- Generates enough activation dates

### Scenario 2: Add New Transaction Type

**Goal:** Add "Money Transfer" transaction type

**Step 1: Add table schema**
```python
con.execute("""
    CREATE TABLE BI.FCT_MONEY_TRANSFER (
        id_date INTEGER,
        msisdn VARCHAR,
        id_subscriber INTEGER,
        amount_transferred INTEGER,
        recipient_msisdn VARCHAR,
        id_location INTEGER
    )
""")
```

**Step 2: Generate data**
```python
transfer_rows = []
for current_day in [20260519, 20260520]:
    for offset in range(8):  # 8 transfers per day
        subscriber = subscribers[(current_day + offset) % len(subscribers)]
        recipient = subscribers[(current_day + offset + 1) % len(subscribers)]
        transfer_rows.append((
            current_day,
            subscriber.msisdn,
            subscriber.id_subscriber,
            10000 + offset * 500,  # 10K-14K Birr
            recipient.msisdn,
            subscriber.location_id,
        ))

con.executemany(
    "INSERT INTO BI.FCT_MONEY_TRANSFER VALUES (?, ?, ?, ?, ?, ?)",
    transfer_rows,
)
```

**Step 3: Add SQL query to test2.sql**
```sql
--------------------------------MONEY TRANSFER DAILY---------------------------------------------------

SELECT id_date,
       COUNT(DISTINCT msisdn) AS users,
       SUM(amount_transferred) / 100 AS total_amount
FROM BI.FCT_MONEY_TRANSFER
WHERE id_date BETWEEN 20260519 AND 20260520
GROUP BY id_date
ORDER BY id_date;
```

**Step 4: Rebuild and run**
```bash
python mock_warehouse.py build
python mock_warehouse.py run
```

### Scenario 3: Change Date Range

**Current:** 120 days (Feb 20 - Jun 19, 2026)
**Goal:** 30 days (May 20 - Jun 19, 2026)

**Step 1: Update constant**
```python
WINDOW_DAYS = 30  # Changed from 120
```

**Step 2: Rebuild**
```bash
python mock_warehouse.py build
```

**What changes:**
- Faster builds
- Less data (30 vs 120 days)
- Queries with 90-day windows won't have enough data
- Good for quick testing

### Scenario 4: Match Specific Real-World Metrics

**Example:** Your real data shows 500K daily active subscribers, but we only have ~200

**Step 1: Increase subscribers**
```python
for index in range(1, 10001):  # 10K subscribers instead of 240
```

**Step 2: Increase activity density**
```python
# In daily_rows generation
for offset in range(40):  # was 14, now 40 per day
    # Same code
```

**Step 3: Adjust financial amounts**
```python
# In fin_rows generation
fin_rows.append((
    ...
    5000 + offset * 1000,  # was 230500, now 5000-5000K to scale
    ...
))
```

### Scenario 5: Add New Column to Existing Table

**Example:** Add `customer_type` to subscriber table

**Step 1: Modify schema**
```python
con.execute("""
    CREATE TABLE BI.REF_SUBSCRIBER (
        id_subscriber INTEGER,
        ds_msisdn VARCHAR,
        ds_activation_date INTEGER,
        ds_exec_region VARCHAR,
        x_staff_flag INTEGER,
        customer_type VARCHAR  -- NEW: "Prepaid", "Postpaid", etc.
    )
""")
```

**Step 2: Generate values**
```python
customer_types = ["Prepaid", "Postpaid", "Corporate"]

con.executemany(
    "INSERT INTO BI.REF_SUBSCRIBER VALUES (?, ?, ?, ?, ?, ?)",
    [
        (
            sub.id_subscriber,
            sub.msisdn,
            sub.activation_date,
            sub.exec_region,
            sub.staff_flag,
            customer_types[sub.id_subscriber % 3],  # Distribute types
        )
        for sub in subscribers
    ]
)
```

**Step 3: Use in queries**
```sql
SELECT customer_type,
       COUNT(DISTINCT msisdn) AS subs
FROM BI.REF_SUBSCRIBER
GROUP BY customer_type;
```

### Scenario 6: Add Seasonal Data Patterns

**Example:** More activity on weekends, less on weekdays

**Step 1: Create helper function**
```python
def get_activity_multiplier(date_obj: date) -> float:
    """Return activity multiplier based on day of week.
    
    Monday (0) = 0.8x (low activity)
    Friday (4) = 1.2x (high activity)
    Saturday (5) = 1.5x (peak)
    Sunday (6) = 1.3x (high)
    """
    weekday = date_obj.weekday()
    if weekday == 4:  # Friday
        return 1.2
    elif weekday == 5:  # Saturday
        return 1.5
    elif weekday == 6:  # Sunday
        return 1.3
    elif weekday < 4:
        return 0.8
    return 1.0
```

**Step 2: Apply in data generation**
```python
for day_index, current_day in enumerate(report_days):
    multiplier = get_activity_multiplier(current_day)
    num_records = int(14 * multiplier)  # Base 14, adjusted
    
    for offset in range(num_records):
        # Generate records
```

### Scenario 7: Add Real Data Integration

**Eventually:** Replace mock data with real data

**Step 1: Read from real source**
```python
def load_real_subscribers() -> list[Subscriber]:
    """Load actual subscribers from company database.
    
    Connect to Oracle, run query, parse results
    """
    import oracledb  # or your DB library
    
    conn = oracledb.connect("user/password@database")
    cursor = conn.cursor()
    cursor.execute("SELECT id_subscriber, msisdn, ... FROM REF_SUBSCRIBER")
    
    subscribers = []
    for row in cursor:
        subscribers.append(Subscriber(...))
    
    return subscribers
```

**Step 2: Hybrid approach**
```python
# Use real subscribers but generate mock transactions
real_subscribers = load_real_subscribers()
generate_mock_transactions(real_subscribers)
```

---

## Troubleshooting & Debugging

### Issue 1: SQL Rewriter Fails

**Symptom:** Query runs but produces wrong results

**Debug:**
```python
# Add to rewrite_sql() to see what's happening
print("BEFORE:", sql_text[:200])
# ... rewriting code ...
print("AFTER:", sql_text[:200])
```

**Common problems:**
```python
# Problem: Date regex too narrow
r"to_char\(to_date\('(?P<date>\d{8})'..."
# Fix: Handle variations
r"to_char\s*\(\s*to_date\s*\(\s*'(?P<date>\d{8})'..."

# Problem: NVL in nested CASE
WHEN NVL(col1, col2) THEN...
# Fix: Better regex with lookahead
```

### Issue 2: Empty Query Results

**Symptom:** `query_12.csv` returns 0 rows

**Diagnosis:**
```python
# In test_automation.py, add:
print("Query 12 expected to be empty (GA queries)")
print("This is normal if no GA data generated")

# Or debug:
duckdb> SELECT * FROM BI.REF_SUBSCRIBER LIMIT 5;
# Check if activation_date matches query date
```

**Solutions:**
1. Adjust query date filter
2. Adjust `BASE_DATE` to match test dates
3. Add more activation data

### Issue 3: Ambiguous Column Error

**Symptom:**
```
Binder Error: Ambiguous reference to column name "DS_EXEC_REGION"
```

**Root cause:** Query joins multiple tables with same column name

**Solution:**
```python
# In rewrite_sql(), add table alias:
sql_text = re.sub(
    r"\bWHEN\s+DS_EXEC_REGION\s*=",
    r"WHEN b.DS_EXEC_REGION =",  # or appropriate table alias
    sql_text,
    flags=re.I,
)
```

**To debug:**
```sql
-- View query before rewrite
SELECT * FROM test2.sql  -- Find the problematic query
-- Manually fix the aliases
-- Test in DuckDB CLI first
duckdb> ... your query ...
```

### Issue 4: Database Lock Error

**Symptom:**
```
io error: unable to open database file
```

**Causes:**
1. Database still open in another process
2. File permissions issue
3. Disk full

**Solutions:**
```bash
# Kill any Python processes
taskkill /F /IM python.exe

# Or restart terminal
# Or change database path
python mock_warehouse.py build --db test_warehouse.duckdb

# Check disk space
dir C:\ /s
```

### Issue 5: Date Arithmetic Wrong

**Symptom:** Query expects 30-day window but we only have 5 days

**Debug:**
```python
# Print actual dates being generated
report_start = BASE_DATE - timedelta(days=WINDOW_DAYS - 1)
report_days = [day for day in date_range(report_start, WINDOW_DAYS)]
print(f"First: {report_days[0]}, Last: {report_days[-1]}")
# Output: First: 2026-02-20, Last: 2026-06-19

# Check what query expects
# test2.sql:
# WHERE id_date >= 20260520
#   AND id_date <= 20260520
# This only queries 1 day!
```

**Solution:** Adjust query or date range to match

### Issue 6: Performance - Build Too Slow

**Symptom:** `python mock_warehouse.py build` takes 2+ minutes

**Root cause:** Too much data

**Solutions:**
```python
# Reduce subscribers
for index in range(1, 101):  # was 241

# Reduce window
WINDOW_DAYS = 30  # was 120

# Reduce transactions
for offset in range(5):  # was 14
```

### Debug Mode - Add Logging

**Create debug version:**
```python
DEBUG = True

def build_database(db_path: Path) -> None:
    if DEBUG:
        print(f"🔨 Building to {db_path}")
    
    subscribers = build_subscribers()
    if DEBUG:
        print(f"📊 Generated {len(subscribers)} subscribers")
        print(f"   Regions: {set(s.exec_region for s in subscribers)}")
        print(f"   Date range: {subscribers[0].activation_date} - {subscribers[-1].activation_date}")
    
    # ... rest of code
```

### Inspecting Database

**Use DuckDB CLI:**
```bash
duckdb mock_warehouse.duckdb

# List tables
.tables

# View schema
.schema TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS

# Sample data
SELECT * FROM BI.REF_SUBSCRIBER LIMIT 5;
SELECT COUNT(*) FROM TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS;
SELECT DISTINCT id_date FROM TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS ORDER BY id_date;

# Test a query
SELECT id_date, COUNT(DISTINCT msisdn) FROM TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS
GROUP BY id_date ORDER BY id_date;
```

---

## Quick Reference - Adding Features Checklist

When adding a new feature, follow this checklist:

### Adding New Data Table

- [ ] Add schema definition in `build_database()`
- [ ] Create row tuples in appropriate loop
- [ ] Use `executemany()` to insert
- [ ] Add to `.schema` query to verify
- [ ] Test with simple SELECT

### Adding New Business Logic

- [ ] Create helper function (e.g., `get_activity_multiplier()`)
- [ ] Call in appropriate data generation loop
- [ ] Add logging/debug output
- [ ] Rebuild: `python mock_warehouse.py build`
- [ ] Verify with test query

### Adding New SQL Query

- [ ] Add to `test2.sql` in proper section (with `---SEPARATOR---`)
- [ ] Use existing table/column names
- [ ] Test date range matches `BASE_DATE`
- [ ] Run: `python mock_warehouse.py run`
- [ ] Verify CSV output in `outputs/`

### Adding New Validation

- [ ] Add function to `test_automation.py`
- [ ] Call in `main()` after `run_queries()`
- [ ] Test: `python test_automation.py`
- [ ] Verify output shows pass/fail

---

## Summary

**Key Takeaways:**

1. **Architecture:** SQL → Rewriter → Executor → CSV
2. **Data:** 240 subs × 120 days × transactions = ~3K records
3. **DuckDB:** Local SQL engine, no setup needed
4. **Extensible:** Change constants, add tables, modify queries
5. **Testable:** Automation framework validates all queries

**To understand better:**
- Read comments in each function
- Add `print()` statements to trace execution
- Use `duckdb` CLI to inspect data
- Start with small changes (1 table, 1 column)
- Test after each change

**You now have:**
- ✅ Working mock warehouse
- ✅ 19 automated queries
- ✅ Testing framework
- ✅ Extensible architecture
- ✅ Full documentation

**Next steps for you:**
1. Run the system as-is (confirm it works)
2. Make small changes (add 1 column, 1 table)
3. Add custom queries matching your needs
4. Integrate into your automation workflow
