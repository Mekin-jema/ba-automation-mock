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
