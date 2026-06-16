# Mock Warehouse - Code Walkthrough & Examples

## Running the System - Practical Guide

### Command 1: Build the Database

```bash
python mock_warehouse.py build
```

**What happens:**

```
Step 1: Parser reads command-line arguments
   Command detected: "build"
   
Step 2: Define paths
   db_path = Path("mock_warehouse.duckdb")
   
Step 3: Check if old database exists
   if db_path.exists(): db_path.unlink()  # Delete old
   
Step 4: Call build_database()
   ├─ Generates 240 subscribers (Subscriber objects)
   ├─ Calculates date range (120 days)
   ├─ Opens DuckDB connection
   ├─ Creates schemas: BI, TIGIST_KEBEDE
   ├─ Creates 10 tables with correct columns
   ├─ Inserts regions (11 rows)
   ├─ Inserts subscribers (240 rows)
   ├─ Inserts accounts & products (reference data)
   ├─ Generates & inserts 1,680 daily active records
   ├─ Generates & inserts financial transaction records
   ├─ Generates & inserts traffic records
   └─ Closes connection
   
Step 5: Print completion message
   Output: "built mock_warehouse.duckdb"
```

**Result:** 
- ✅ `mock_warehouse.duckdb` created (~2.6 MB)
- ✅ All tables populated with synthetic data
- ✅ Ready for SQL queries

---

### Command 2: Run All Queries

```bash
python mock_warehouse.py run
```

**What happens:**

```
Step 1: Parser reads command-line arguments
   Command detected: "run"
   
Step 2: Check if database exists
   if not db_path.exists():
       build_database(db_path)  # Auto-rebuild if missing
   
Step 3: Call run_sql(db_path, sql_file, output_dir)
   
   a) Read SQL file into memory
      sql_text = Path("test2.sql").read_text()
      # Now we have all 19 queries as one string
   
   b) Rewrite Oracle SQL to DuckDB
      sql_text = rewrite_sql(sql_text)
      # Removes hints, converts dates, etc.
   
   c) Split into individual queries
      statements = split_statements(sql_text)
      # Now we have 19 separate SELECT statements
   
   d) Open database connection
      con = duckdb.connect("mock_warehouse.duckdb")
   
   e) For each of 19 queries:
      ├─ Execute: cursor = con.execute(statement)
      ├─ Fetch: rows = cursor.fetchall()
      ├─ Get columns: column_names = [col[0] for col in cursor.description]
      ├─ Write CSV: query_01.csv, query_02.csv, ..., query_19.csv
      └─ Print: "query 01: X rows -> outputs/query_01.csv"
   
   f) Close connection
      con.close()
```

**Output:**
```
query 01: 1 rows -> outputs/query_01.csv
query 02: 1 rows -> outputs/query_02.csv
query 03: 11 rows -> outputs/query_03.csv
...
query 19: 4 rows -> outputs/query_19.csv
```

**Result:**
- ✅ 19 CSV files created in `outputs/`
- ✅ Each file contains query results
- ✅ Ready for testing/analysis

---

## Code Deep Dive - Key Functions

### Function 1: Generate Subscribers

```python
def build_subscribers() -> list[Subscriber]:
    """
    Purpose: Create 240 realistic mock subscribers
    
    Input: None (uses global BASE_DATE)
    Output: List of 240 Subscriber objects
    
    Example output:
        [
            Subscriber(
                id_subscriber=1,
                msisdn="25190000001",
                activation_date=20260403,
                exec_region="West Addis",
                staff_flag=0,
                location_id=1,
            ),
            Subscriber(
                id_subscriber=2,
                msisdn="25190000002",
                activation_date=20260404,
                exec_region="East Addis",
                staff_flag=0,
                location_id=2,
            ),
            ...
        ]
    """
    subscribers: list[Subscriber] = []
    
    # Loop from 1 to 240
    for index in range(1, 241):
        
        # Assign region (round-robin across 11 regions)
        region = REGIONS[(index - 1) % len(REGIONS)]
        # index=1: (0) % 11 = 0 → "West Addis"
        # index=2: (1) % 11 = 1 → "East Addis"
        # index=11: (10) % 11 = 10 → "Afar"
        # index=12: (11) % 11 = 0 → "West Addis" (cycle repeats)
        
        # Assign location_id (1-11 matching region)
        location_id = (index - 1) % len(REGIONS) + 1
        # +1 converts 0-10 to 1-11
        
        # Generate random activation date
        # Activated between 40-120 days ago
        activation_date = day_key(
            BASE_DATE - timedelta(days=40 + (index % 80))
        )
        # index=1: 40+1=41 days ago
        # index=80: 40+0=40 days ago
        # index=81: 40+1=41 days ago
        # Spreads activations over 40-120 day window
        
        # Mark every 17th subscriber as staff (~7%)
        staff_flag = 1 if index % 17 == 0 else 0
        # index=17: 17 % 17 = 0 → staff_flag = 1
        # index=34: 34 % 17 = 0 → staff_flag = 1
        # index=1: 1 % 17 = 1 → staff_flag = 0
        
        # Create Subscriber object
        subscribers.append(
            Subscriber(
                id_subscriber=index,
                msisdn=make_msisdn(index),  # "25190000001"
                activation_date=activation_date,
                exec_region=region,
                staff_flag=staff_flag,
                location_id=location_id,
            )
        )
    
    return subscribers  # 240 Subscriber objects
```

---

### Function 2: Rewrite SQL for DuckDB

```python
def rewrite_sql(sql_text: str) -> str:
    """
    Purpose: Convert Oracle SQL to DuckDB-compatible SQL
    
    Input:
        SELECT /*+ parallel(32)*/  count(distinct msisdn)
            FROM  TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS
            WHERE id_date >= to_char(to_date('20260520','YYYYMMDD') - 29,'YYYYMMDD')
    
    Output:
        SELECT count(distinct msisdn)
            FROM  TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS
            WHERE id_date >= 20260491
    
    Steps:
    """
    
    # Helper: Convert date arithmetic to pre-computed values
    def replace_date_expression(match: re.Match[str]) -> str:
        """
        Converts: to_char(to_date('20260520','YYYYMMDD') - 29, 'YYYYMMDD')
        To:       20260491
        
        Logic:
        1. Extract date: "20260520"
        2. Extract delta: "-29"
        3. Parse date: date(2026, 5, 20)
        4. Apply delta: date(2026, 5, 20) - 29 days = date(2026, 4, 21)
        5. Convert to integer: 20260421
        """
        report_date = datetime.strptime(
            match.group("date"),  # "20260520"
            "%Y%m%d"
        ).date()  # date(2026, 5, 20)
        
        delta_text = (match.group("delta") or "0").replace(" ", "")
        # "- 29" → "-29" (remove spaces)
        delta = int(delta_text)  # -29
        
        result_date = report_date + timedelta(days=delta)
        # date(2026, 5, 20) + (-29 days) = date(2026, 4, 21)
        
        return str(day_key(result_date))
        # day_key(date(2026, 4, 21)) → 20260421
    
    # 1. Remove Oracle hints: /*+ PARALLEL(32) */
    sql_text = re.sub(
        r"/\*\+.*?\*/",  # Match /* + anything ... */
        "",              # Replace with nothing
        sql_text,
        flags=re.I | re.S  # Case-insensitive, allow newlines in pattern
    )
    # Result: "SELECT /*+ parallel(32)*/" → "SELECT"
    
    # 2. Convert NVL to COALESCE
    sql_text = re.sub(
        r"\bNVL\s*\(",  # Match "NVL(" with optional spaces
        "COALESCE(",     # Replace with "COALESCE("
        sql_text,
        flags=re.I
    )
    # Result: "NVL(col, 0)" → "COALESCE(col, 0)"
    
    # 3. Convert complex date arithmetic
    sql_text = re.sub(
        r"to_char\s*\(\s*to_date\(\s*'(?P<date>\d{8})'\s*,\s*'YYYYMMDD'\s*\)\s*(?P<delta>[-+]\s*\d+)?\s*,\s*'YYYYMMDD'\s*\)",
        # Pattern explanation:
        # - to_char\s*\( : match "to_char(" with optional spaces
        # - to_date\s*\( : match "to_date(" with optional spaces
        # - '(?P<date>\d{8})' : match 8-digit date like "20260520"
        # - 'YYYYMMDD' : format string
        # - (?P<delta>[-+]\s*\d+)? : optional "+ 29" or "- 29"
        # - 'YYYYMMDD' : output format
        replace_date_expression,
        sql_text,
        flags=re.I,
    )
    # Result: "to_char(to_date('20260520','YYYYMMDD') - 29,'YYYYMMDD')"
    #      → "20260491"
    
    # 4. Handle simpler date conversions
    sql_text = sql_text.replace(
        "to_date('20260520','YYYYMMDD')",  # Full Oracle syntax
        "20260520"                          # Just the integer
    )
    sql_text = sql_text.replace(
        "to_date('20260519','YYYYMMDD')",
        "20260519"
    )
    
    # 5. Fix ambiguous column references
    sql_text = re.sub(
        r"\bWHEN\s+DS_EXEC_REGION\s*=",  # Match "WHEN DS_EXEC_REGION ="
        r"WHEN b.DS_EXEC_REGION =",      # Add table alias "b."
        sql_text,
        flags=re.I,
    )
    # Result: "WHEN DS_EXEC_REGION = 'West Addis'"
    #      → "WHEN b.DS_EXEC_REGION = 'West Addis'"
    
    return sql_text
```

---

### Function 3: Split SQL Statements

```python
def split_statements(sql_text: str) -> list[str]:
    """
    Purpose: Extract 19 individual SELECT queries from test2.sql
    
    Input: Entire test2.sql file (one big string with comments)
    
    Output: ["SELECT ...", "SELECT ...", ..., "SELECT ..."]
    
    Example input:
        --------------------------------QUERY 1--------------------------------------
        SELECT id_date, count(distinct msisdn)
        FROM TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS
            WHERE id_date >= 20260520
        GROUP BY id_date
        ORDER BY id_date;
        
        --------------------------------QUERY 2--------------------------------------
        SELECT count(distinct msisdn)
        FROM TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS
        WHERE id_date >= 20260520;
    
    Output:
        [
            "SELECT id_date, count(distinct msisdn)\\nFROM ...",
            "SELECT count(distinct msisdn)\\nFROM ...",
        ]
    """
    
    lines = sql_text.split("\n")
    # Split entire file into lines
    
    statements: list[str] = []
    current_statement: list[str] = []
    
    for line in lines:
        stripped = line.strip()
        
        # 1. Detect divider comments (many dashes)
        if re.match(r"^-{20,}", stripped):
            # This is a section divider like "--------QUERY 1--------"
            
            # Save previous statement if exists
            if current_statement:
                full_stmt = "\n".join(current_statement).strip()
                if full_stmt and not re.match(r"^-{20,}", full_stmt):
                    statements.append(full_stmt)
                current_statement = []
            continue
        
        # 2. Skip empty lines and comments
        if not stripped or stripped.startswith("--"):
            current_statement.append(line)
            continue
        
        # 3. Add line to current statement
        current_statement.append(line)
        
        # 4. Check if statement ends with semicolon
        if stripped.endswith(";"):
            full_stmt = "\n".join(current_statement).strip()
            if full_stmt and not re.match(r"^-{20,}", full_stmt):
                statements.append(full_stmt)
            current_statement = []
    
    # 5. Don't forget last statement
    if current_statement:
        full_stmt = "\n".join(current_statement).strip()
        if full_stmt and not re.match(r"^-{20,}", full_stmt):
            statements.append(full_stmt)
    
    # 6. Filter to only SELECT statements
    return [
        stmt for stmt in statements 
        if stmt.upper().startswith("SELECT")
    ]
    # This removes any leftover comments or non-query text
```

---

### Function 4: Run SQL and Export Results

```python
def run_sql(db_path: Path, sql_path: Path, output_dir: Path) -> None:
    """
    Purpose: Execute all queries and save results to CSV
    
    Input:
        db_path: Path("mock_warehouse.duckdb")
        sql_path: Path("test2.sql")
        output_dir: Path("outputs")
    
    Output:
        Creates outputs/query_01.csv, query_02.csv, ..., query_19.csv
    
    Process:
    """
    
    # Create output directory if not exists
    output_dir.mkdir(parents=True, exist_ok=True)
    # parents=True: create parent directories if needed
    # exist_ok=True: don't error if already exists
    
    # Read and process SQL
    sql_text = rewrite_sql(
        sql_path.read_text(encoding="utf-8-sig")
    )
    # utf-8-sig: handles BOM (byte order mark) if present
    
    statements = split_statements(sql_text)
    # Now we have 19 individual SELECT statements
    
    # Connect to database
    with duckdb.connect(str(db_path)) as con:
        # "with" ensures connection closes even if error occurs
        
        # Execute each query
        for index, statement in enumerate(statements, start=1):
            # enumerate(start=1) gives us 1, 2, 3, ... not 0, 1, 2, ...
            
            # Execute query
            cursor = con.execute(statement)
            
            # Skip if query doesn't return rows (e.g., INSERT, UPDATE)
            if cursor.description is None:
                continue
            
            # Fetch all results
            rows = cursor.fetchall()
            # rows = [(val1, val2, ...), (val1, val2, ...), ...]
            
            # Extract column names
            columns = [column[0] for column in cursor.description]
            # cursor.description = [(name, type, ...), (name, type, ...), ...]
            # We extract just the names: [name1, name2, ...]
            
            # Create output filename
            output_path = output_dir / f"query_{index:02d}.csv"
            # f"query_{1:02d}.csv" → "query_01.csv"
            # f"query_{19:02d}.csv" → "query_19.csv"
            
            # Write CSV file
            with output_path.open("w", newline="", encoding="utf-8") as handle:
                # newline="" : recommended for CSV writer
                
                writer = csv.writer(handle)
                writer.writerow(columns)  # Write header
                # Writes: ["id_date", "count(DISTINCT msisdn)"]
                
                writer.writerows(rows)    # Write data rows
                # Writes each tuple from rows
            
            # Print progress
            print(
                f"query {index:02d}: {len(rows)} rows -> {output_path}"
            )
            # Output: "query 01: 1 rows -> outputs/query_01.csv"
```

---

## Practical Examples - Extending the System

### Example 1: Add "Premium Subscriber" Flag

**Goal:** Mark some subscribers as premium customers

**Step 1: Update Subscriber class**
```python
@dataclass(frozen=True)
class Subscriber:
    id_subscriber: int
    msisdn: str
    activation_date: int
    exec_region: str
    staff_flag: int
    location_id: int
    is_premium: int  # NEW: 0 or 1
```

**Step 2: Generate premium flag**
```python
def build_subscribers() -> list[Subscriber]:
    subscribers: list[Subscriber] = []
    for index in range(1, 241):
        region = REGIONS[(index - 1) % len(REGIONS)]
        location_id = (index - 1) % len(REGIONS) + 1
        activation_date = day_key(BASE_DATE - timedelta(days=40 + (index % 80)))
        staff_flag = 1 if index % 17 == 0 else 0
        
        # NEW: Mark 20% as premium (every 5th subscriber)
        is_premium = 1 if index % 5 == 0 else 0
        
        subscribers.append(
            Subscriber(
                id_subscriber=index,
                msisdn=make_msisdn(index),
                activation_date=activation_date,
                exec_region=region,
                staff_flag=staff_flag,
                location_id=location_id,
                is_premium=is_premium,  # NEW
            )
        )
    return subscribers
```

**Step 3: Create table with new column**
```python
def build_database(db_path: Path) -> None:
    # ... existing code ...
    
    con.execute("""
        CREATE TABLE BI.REF_SUBSCRIBER (
            id_subscriber INTEGER,
            ds_msisdn VARCHAR,
            ds_activation_date INTEGER,
            ds_exec_region VARCHAR,
            x_staff_flag INTEGER,
            is_premium INTEGER  -- NEW
        )
    """)
    
    con.executemany(
        "INSERT INTO BI.REF_SUBSCRIBER VALUES (?, ?, ?, ?, ?, ?)",
        [
            (
                sub.id_subscriber,
                sub.msisdn,
                sub.activation_date,
                sub.exec_region,
                sub.staff_flag,
                sub.is_premium,  # NEW
            )
            for sub in subscribers
        ]
    )
```

**Step 4: Use in SQL**
```sql
-- Add this query to test2.sql

--------------------------------PREMIUM SUBSCRIBER COUNT---------------------------------------------------

SELECT is_premium,
       COUNT(DISTINCT ds_msisdn) AS count
FROM BI.REF_SUBSCRIBER
GROUP BY is_premium
ORDER BY is_premium;
```

**Step 5: Test**
```bash
python mock_warehouse.py build
python mock_warehouse.py run
# Check outputs/query_NN.csv for your new query
```

---

### Example 2: Add Weighted Region Distribution

**Goal:** Make West Addis have 50% of subscribers, others split remainder

**Current:** Uniform distribution (240 / 11 = 22 per region)
**Target:** West Addis = 120, others split 120

**Implementation:**
```python
def build_subscribers() -> list[Subscriber]:
    subscribers: list[Subscriber] = []
    
    # Generate 120 West Addis subscribers
    for index in range(1, 121):
        region = "West Addis"
        location_id = 1  # West Addis is region 1
        # ... rest of code
    
    # Generate other regions
    region_index = 1
    for index in range(121, 241):
        region = REGIONS[region_index]
        location_id = region_index + 1
        
        # Move to next region every 11 subscribers
        if (index - 121) % 11 == 0:
            region_index = (region_index + 1) % 11
        
        # ... rest of code
```

---

### Example 3: Add Monthly Statistics Query

**Goal:** Generate query that aggregates by month

**New Query:**
```sql
--------------------------------MONTHLY ACTIVE SUBSCRIBERS---------------------------------------------------

SELECT 
    SUBSTR(CAST(id_date AS VARCHAR), 1, 6) AS month,
    COUNT(DISTINCT msisdn) AS monthly_subs
FROM TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS
GROUP BY SUBSTR(CAST(id_date AS VARCHAR), 1, 6)
ORDER BY month;
```

**How it works:**
- `CAST(id_date AS VARCHAR)` converts "20260520" to string
- `SUBSTR(..., 1, 6)` extracts first 6 chars: "202605" (year-month)
- `COUNT(DISTINCT msisdn)` counts unique subscribers per month
- `GROUP BY month` aggregates by month

**Add to test2.sql:**
```
Add before `if __name__ == "__main__":`
```

**Run:**
```bash
python mock_warehouse.py run
# Outputs a new query_NN.csv with monthly aggregates
```

---

### Example 4: Conditional Data Generation

**Goal:** Generate more transactions on peak days

**Before:**
```python
for current_day in traffic_dates:
    for offset, (account_id, product_id, ...) in enumerate(traffic_template):
        subscriber = subscribers[...]
        traffic_rows.append((current_day, ...))
```

**After:**
```python
def is_peak_day(date_int: int) -> bool:
    """Check if date is a peak day (weekend, holiday, etc.)"""
    # Convert 20260520 to date(2026, 5, 20)
    date_obj = datetime.strptime(str(date_int), "%Y%m%d").date()
    weekday = date_obj.weekday()
    
    # Weekend = more traffic
    return weekday >= 4  # Friday=4, Saturday=5, Sunday=6

for current_day in traffic_dates:
    base_count = 7 if is_peak_day(current_day) else 5
    
    for offset in range(base_count):
        subscriber = subscribers[...]
        traffic_rows.append((current_day, ...))
```

---

## Testing & Validation Checklist

**Before adding to production:**

```python
# 1. Check data exists
duckdb mock_warehouse.duckdb
  .tables
  SELECT COUNT(*) FROM BI.REF_SUBSCRIBER;

# 2. Run quick query
python mock_warehouse.py run

# 3. Validate results
python test_automation.py

# 4. Spot-check CSV
head -5 outputs/query_01.csv

# 5. Check for errors
tail -20 outputs/query_*.csv  # Look for ERROR messages

# 6. Verify metrics
python test_automation.py | grep -i "metric\|error\|warning"
```

---

## Summary for Quick Reference

| Task | Code |
|------|------|
| Run build | `python mock_warehouse.py build` |
| Run queries | `python mock_warehouse.py run` |
| Test all | `python test_automation.py` |
| Add subscriber field | Modify `Subscriber` dataclass, update `build_subscribers()`, update SQL insert, add table column |
| Add transaction type | Create new table, generate transaction data, add SQL query |
| Add query | Write SQL in test2.sql, run `python mock_warehouse.py run` |
| Debug data | Use `duckdb mock_warehouse.duckdb` CLI |
| View results | Open `outputs/query_NN.csv` in Excel |

**Happy extending! 🚀**
