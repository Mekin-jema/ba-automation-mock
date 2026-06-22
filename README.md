# DA Report Pipeline

## Project layout
- `src/` — pipeline entry points and automation scripts
- `outputs/` — generated CSV/XLSX reports
- `data/` — input SQL files and sample datasets
  - `data/sql/` — SQL workbooks
  - `data/sample/` — template CSVs
  - `data/db/` — DuckDB database files
- `docs/` — project guides and documentation
- `Dockerfile` and `docker-compose.yaml` — container setup for Jenkins/dev environment

## How to run
1. `python src/mock_warehouse.py build`
2. `python src/mock_warehouse.py run`
3. `python src/generate_dashboard.py`
4. `python src/generate_report.py`

## Running for a specific day or date range
- Run for one day:
  `python src/mock_warehouse.py run --date 20260521`
- Run for a full inclusive range:
  `python src/mock_warehouse.py run --start-date 20260519 --end-date 20260521`
- If neither date option is provided, the script uses yesterday by default.
- Use either `--date` or `--start-date`/`--end-date`, not both together.
