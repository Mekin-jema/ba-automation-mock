# User Guide — Quick & Simple

This single guide merges the essential user-facing documentation so you can get started and run the system without navigating multiple files.

## Contents
- Quick start (3 commands)
- What the system provides
- How to run & common commands
- Quick troubleshooting
- Quick modifications examples
- Next steps and checks

---

## Quick Start (3 commands)
```bash
pip install -r requirements.txt
python mock_warehouse.py build
python mock_warehouse.py run
```
Results: outputs/query_01.csv … query_19.csv

---

## What the system provides
- Local DuckDB mock database: `mock_warehouse.duckdb`
- Synthetic data: 240 subscribers × 120 days
- 19 SQL queries from `test2.sql` executed locally
- CSV outputs in `outputs/`

---

## How to Run (Common Options)
- Build (one-time): `python mock_warehouse.py build`
- Run queries: `python mock_warehouse.py run`
- Run with custom output: `python mock_warehouse.py run --out my_outputs`
- Rebuild DB: `python mock_warehouse.py build --db my.db`
- Test automation: `python test_automation.py`

---

## Quick Troubleshooting
- `ModuleNotFoundError: duckdb` → `pip install duckdb`
- `0 rows returned` for some queries → expected for GA queries
- `Ambiguous column` → `python mock_warehouse.py build` then `run`
- `File locked` → close any Python/duckdb processes

---

## Quick Modifications (Examples)
- Add more subscribers: change loop in `build_subscribers()` to `range(1,1001)` and rebuild
- Change date range: edit `WINDOW_DAYS` in `mock_warehouse.py` and rebuild
- Add new query: add SQL to `test2.sql` and run

---

## Verification Checklist
```bash
python mock_warehouse.py build
python mock_warehouse.py run
python test_automation.py
ls outputs/query_*.csv
```

---

## Where to Find More (If Needed)
- For full commands & options: see `MOCK_SETUP_GUIDE.md`
- If you want to extend code: see `IMPLEMENTATION_GUIDE.md` and `CODE_WALKTHROUGH.md`
- Query descriptions: `SQL_OVERVIEW.txt`

---

## Next Steps
1. Run the 3 quick commands
2. Open `outputs/query_01.csv` in Excel
3. If you want to modify, pick a small change (add 1 column) and follow the developer guide

