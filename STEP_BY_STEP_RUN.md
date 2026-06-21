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

## Output

The final report will be saved here:

```
outputs/real-sample-report-pivoted.csv
```
