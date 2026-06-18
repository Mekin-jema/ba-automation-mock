#!/usr/bin/env python3
"""
Generate Dashboard - Merge query results into the CBU Stand-Up Report format.
Pivots the SQL output data so that dates are columns, matching the layout of real-sample-report.csv.
Accumulates historical columns day-by-day.
"""

from pathlib import Path
from datetime import datetime
import pandas as pd
import numpy as np

# =========================
# PATHS
# =========================
WORKSPACE_DIR = Path(__file__).parent
OUTPUTS_DIR = WORKSPACE_DIR / "outputs"
TEMPLATE_PATH = WORKSPACE_DIR / "real-sample-report.csv"
OUTPUT_REPORT_PATH = OUTPUTS_DIR / "real-sample-report-pivoted.csv"

# =========================
# GLOBAL CACHE (FIXED BUG)
# =========================
df_cache = {}

# =========================
# FILE LIST
# =========================
NAMED_FILES = [
    "DAILY_ACTIVE_SUBS.csv",
    "30_DAYIS_DAILY.csv",
    "90_DAY_DAILY.csv",
    "DAILY_ACTIVE_SUB_REGIONAL.csv",
    "RECHARGE_DAILY.csv",
    "RECHARGE_REGIONAL.csv",
    "LOAN_DAILY.csv",
    "LOAN_REGIONAL.csv",
    "REPAYMENT_DAILY.csv",
    "REPAYMENT_REGIONAL.csv",
    "DIRECT_BUNDLE_PURCHASE_DAILY.csv",
    "DIRECT_BUNDLE_PURCHASE_REGIONAL.csv",
    "GA_DAILY.csv",
    "GA_REGIONAL.csv",
    "VOICE_DAILY.csv",
    "VOICE_REGIONAL.csv",
    "DATA_DAILY.csv",
    "DATA_REGIONAL.csv",
    "SMS_DAILY.csv",
    "SMS_REGIONAL.csv",
]

# =========================
# DATA LOADING
# =========================
def get_named_df(filename: str) -> pd.DataFrame:
    path = OUTPUTS_DIR / filename
    if not path.exists():
        return None

    if filename not in df_cache:
        df_cache[filename] = pd.read_csv(path, dtype=str)

    return df_cache[filename]


def clean_region_name(val) -> str:
    if not isinstance(val, str):
        return ""
    val = val.strip()
    if "." in val:
        val = val.split(".", 1)[1].strip()
    if val.lower() in ["uknown", "unknown"]:
        val = "Unknown"
    return val


def format_date_headers(date_int: int):
    try:
        dt = datetime.strptime(str(date_int), "%Y%m%d")
        return dt.strftime("%a"), f"{dt.day}-{dt.strftime('%b')}"
    except Exception:
        return "", str(date_int)


def get_unique_dates():
    dates = set()

    for filename in NAMED_FILES:
        df = get_named_df(filename)
        if df is None or df.empty:
            continue

        date_col = "REPORT_DATE" if "REPORT_DATE" in df.columns else df.columns[0]

        for d in df[date_col].dropna().unique():
            try:
                d_str = str(int(float(d)))
                if len(d_str) == 8:
                    dates.add(int(d_str))
            except:
                pass

    return sorted(list(dates))


def format_cell_value(val, is_percentage=False):
    if val is None or pd.isna(val) or val == "":
        return ""

    try:
        if is_percentage:
            return f"{float(val) * 100:.1f}%"
        return f"{int(round(float(val))):,}"
    except:
        return str(val)


def calculate_ratio(num, den):
    return num / den if den else 0.0


def extract_metric(filename, date_int, value_col, region_name=None):
    df = get_named_df(filename)
    if df is None or df.empty:
        return 0.0

    report_date_col = "REPORT_DATE" if "REPORT_DATE" in df.columns else df.columns[0]

    df_date = df[df[report_date_col].astype(str) == str(date_int)]
    if df_date.empty:
        return 0.0

    if region_name:
        region_col = next((c for c in df_date.columns if "region" in c.lower()), None)
        if not region_col:
            return 0.0

        df_region = df_date[df_date[region_col].apply(clean_region_name) == clean_region_name(region_name)]

        if value_col in df_region.columns and not df_region.empty:
            return float(df_region[value_col].iloc[0])

        return 0.0

    if value_col in df_date.columns:
        return float(pd.to_numeric(df_date[value_col], errors="coerce").sum())

    return 0.0


# =========================
# MAIN ENGINE
# =========================
def generate_dashboard():
    if not TEMPLATE_PATH.exists():
        print("Template missing")
        return

    print("Reading template...")
    template_lines = [l.strip("\n") for l in open(TEMPLATE_PATH, "r", encoding="utf-8")]

    row_labels = [line.split("\t")[0] for line in template_lines]

    history_map = {}
    history_headers = {}
    ordered_date_labels = []

    # Load history
    if OUTPUT_REPORT_PATH.exists():
        try:
            print("Loading history...")
            lines = open(OUTPUT_REPORT_PATH, "r", encoding="utf-8").readlines()

            if len(lines) > 2:
                days = lines[1].split("\t")[1:]
                dates = lines[2].split("\t")[1:]

                for i in range(min(len(days), len(dates))):
                    history_headers[dates[i]] = days[i]
                    ordered_date_labels.append(dates[i])
                    history_map[dates[i]] = {}

        except Exception as e:
            print("History load failed:", e)

    # Clear cache safely
    df_cache.clear()

    dates = get_unique_dates()
    if not dates:
        print("No data found")
        return

    print("Dates found:", dates)

    regions = [
        "West Addis", "East Addis", "Central", "South", "North West",
        "North East", "East 1", "East 2", "West", "North", "Afar", "Unknown"
    ]

    # FIXED typo: "usb" -> "SUBS"
    block_configs = {
        0: ("DAILY_ACTIVE_SUB_REGIONAL.csv", "VLR_ATTCHED", None, None),
        1: ("RECHARGE_REGIONAL.csv", "SUBS", "RECHARGE_DAILY.csv", "SUBS"),
        2: ("RECHARGE_REGIONAL.csv", "TRAFFIC", None, None),
        3: ("LOAN_REGIONAL.csv", "subs", "LOAN_DAILY.csv", "subs"),
        4: ("LOAN_REGIONAL.csv", "TRAFFIC", None, None),
        5: ("REPAYMENT_REGIONAL.csv", "SUBS", "REPAYMENT_DAILY.csv", "SUBS"),
        6: ("REPAYMENT_REGIONAL.csv", "TRAFFIC", None, None),
    }

    for date_int in dates:
        day, label = format_date_headers(date_int)

        if label not in ordered_date_labels:
            ordered_date_labels.append(label)

        history_headers[label] = day
        history_map[label] = {}

        daily = extract_metric("DAILY_ACTIVE_SUB_REGIONAL.csv", date_int, "VLR_ATTCHED")
        a30 = extract_metric("30_DAYIS_DAILY.csv", date_int, "count(DISTINCT msisdn)")
        a90 = extract_metric("90_DAY_DAILY.csv", date_int, "count(DISTINCT msisdn)")

        history_map[label][3] = format_cell_value(daily)
        history_map[label][4] = format_cell_value(a30)
        history_map[label][5] = format_cell_value(a90)
        history_map[label][6] = format_cell_value(calculate_ratio(daily, a30), True)
        history_map[label][7] = format_cell_value(calculate_ratio(a30, a90), True)

        for k, (reg_file, reg_col, nat_file, nat_col) in block_configs.items():
            base = 8 + k * 13

            val = extract_metric(nat_file or reg_file, date_int, nat_col or reg_col)
            history_map[label][base] = format_cell_value(val)

            for i, region in enumerate(regions, 1):
                history_map[label][base + i] = format_cell_value(
                    extract_metric(reg_file, date_int, reg_col, region)
                )

    # Build output
    output_cols = []
    for lbl in ordered_date_labels:
        col = [""] * len(template_lines)
        col[1] = f" {history_headers.get(lbl,'')} "
        col[2] = lbl

        for i in range(3, len(template_lines)):
            col[i] = history_map.get(lbl, {}).get(i, "")

        output_cols.append(col)

    OUTPUTS_DIR.mkdir(exist_ok=True)

    with open(OUTPUT_REPORT_PATH, "w", encoding="utf-8") as f:
        for i in range(len(template_lines)):
            f.write(row_labels[i] + "\t" + "\t".join(col[i] for col in output_cols) + "\n")

    print("Dashboard generated:", OUTPUT_REPORT_PATH)


if __name__ == "__main__":
    generate_dashboard()