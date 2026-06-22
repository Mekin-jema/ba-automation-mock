# How to Run the Project

## Go to Project Folder

Open terminal in:

```
C:\Users\Mekin.Jemal\OneDrive - Safaricom Ethiopia\Desktop\Safaricom\DA
```

## 1. Install Requirements

```powershell
pip install -r requirements.txt
```

## 2. Build Database

```powershell
python mock_warehouse.py build
```

## 3. Run the Project

### Run for yesterday (default)

```powershell
python mock_warehouse.py run
```

### Run for a specific date

```powershell
python mock_warehouse.py run --date 20260619
```

### Run for a date range

Use this when you want to execute the workbook for every day in an inclusive range:

```powershell
python mock_warehouse.py run --start-date 20260519 --end-date 20260521
```

Notes:
- `--date` runs only one day.
- `--start-date` and `--end-date` together run all days between them.
- If you do not pass any date option, the script uses yesterday as the default date.

## Output

The final report will be saved here:

```
outputs/real-sample-report-pivoted.csv
```
