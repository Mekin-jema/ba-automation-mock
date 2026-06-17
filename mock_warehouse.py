from __future__ import annotations

import argparse
import csv
import re
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Iterable

import duckdb


BASE_DATE = date(2026, 5, 20)
WINDOW_DAYS = 120
REGIONS = [
    "West Addis",
    "East Addis",
    "Central",
    "South",
    "North West",
    "North East",
    "East 1",
    "East 2",
    "West",
    "North",
    "Afar",
]


@dataclass(frozen=True)
class Subscriber:
    id_subscriber: int
    msisdn: str
    activation_date: int
    exec_region: str
    staff_flag: int
    location_id: int


def day_key(value: date) -> int:
    return int(value.strftime("%Y%m%d"))


def make_msisdn(index: int) -> str:
    return f"2519{index:08d}"


def date_range(start: date, days: int) -> Iterable[date]:
    for offset in range(days):
        yield start + timedelta(days=offset)


def build_subscribers() -> list[Subscriber]:
    subscribers: list[Subscriber] = []
    for index in range(1, 241):
        region = REGIONS[(index - 1) % len(REGIONS)]
        location_id = (index - 1) % len(REGIONS) + 1
        activation_date = day_key(BASE_DATE - timedelta(days=40 + (index % 80)))
        staff_flag = 1 if index % 17 == 0 else 0
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


def build_database(db_path: Path) -> None:
    if db_path.exists():
        db_path.unlink()

    subscribers = build_subscribers()
    report_start = BASE_DATE - timedelta(days=WINDOW_DAYS - 1)
    report_days = [day for day in date_range(report_start, WINDOW_DAYS)]

    with duckdb.connect(str(db_path)) as con:
        con.execute("CREATE SCHEMA IF NOT EXISTS BI")
        con.execute("CREATE SCHEMA IF NOT EXISTS TIGIST_KEBEDE")

        con.execute(
            """
            CREATE TABLE TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS (
                msisdn VARCHAR,
                id_date INTEGER,
                service_type VARCHAR
            )
            """
        )
        con.execute(
            """
            CREATE TABLE ACTIVATION_MSISDN (
                msisdn VARCHAR,
                exec_region VARCHAR
            )
            """
        )
        con.execute(
            """
            CREATE TABLE BI.REF_LOCATION (
                id_location INTEGER,
                ds_exec_region VARCHAR
            )
            """
        )
        con.execute(
            """
            CREATE TABLE BI.REF_SUBSCRIBER (
                id_subscriber INTEGER,
                ds_msisdn VARCHAR,
                ds_activation_date INTEGER,
                ds_exec_region VARCHAR,
                x_staff_flag INTEGER
            )
            """
        )
        con.execute(
            """
            CREATE TABLE BI.FCT_SUBSCRIBER_ACTIVATION (
                id_subscriber INTEGER,
                id_location_created_user INTEGER
            )
            """
        )
        con.execute(
            """
            CREATE TABLE BI.REF_ACCOUNT (
                id_account INTEGER,
                ds_account_group VARCHAR,
                ds_account_id VARCHAR
            )
            """
        )
        con.execute(
            """
            CREATE TABLE BI.REF_PRODUCT (
                id_product INTEGER,
                x_bundle_type VARCHAR
            )
            """
        )
        con.execute(
            """
            CREATE TABLE BI.FCT_FIN_BLNC_MVMN (
                id_date INTEGER,
                msisdn VARCHAR,
                id_subscriber INTEGER,
                id_results INTEGER,
                id_traffic_type INTEGER,
                id_fin_blnc_mvmn_type INTEGER,
                id_recharge_type INTEGER,
                vl_accnt_blnc INTEGER,
                vl_fee INTEGER,
                vl_accnt_blnc_before INTEGER,
                vl_accnt_blnc_after INTEGER,
                id_account INTEGER,
                x_transaction_id VARCHAR,
                id_location INTEGER
            )
            """
        )
        con.execute(
            """
            CREATE TABLE BI.FCT_TRAFFIC (
                id_date INTEGER,
                calling_msisdn VARCHAR,
                charging_msisdn VARCHAR,
                id_traffic_type INTEGER,
                id_account INTEGER,
                id_product INTEGER,
                id_location_calling INTEGER,
                vl_rate_usage BIGINT,
                id_roaming_type INTEGER,
                x_additional_info VARCHAR
            )
            """
        )

        con.executemany(
            "INSERT INTO BI.REF_LOCATION VALUES (?, ?)",
            [(index + 1, region) for index, region in enumerate(REGIONS)],
        )
        con.executemany(
            "INSERT INTO ACTIVATION_MSISDN VALUES (?, ?)",
            [(subscriber.msisdn, subscriber.exec_region) for subscriber in subscribers],
        )
        con.executemany(
            "INSERT INTO BI.REF_SUBSCRIBER VALUES (?, ?, ?, ?, ?)",
            [
                (
                    subscriber.id_subscriber,
                    subscriber.msisdn,
                    subscriber.activation_date,
                    subscriber.exec_region,
                    subscriber.staff_flag,
                )
                for subscriber in subscribers
            ],
        )
        con.executemany(
            "INSERT INTO BI.FCT_SUBSCRIBER_ACTIVATION VALUES (?, ?)",
            [(subscriber.id_subscriber, subscriber.location_id) for subscriber in subscribers],
        )
        con.executemany(
            "INSERT INTO BI.REF_ACCOUNT VALUES (?, ?, ?)",
            [
                (211, "Account", "BalanceAllowanceLimit-LOAN_SECBAL-211"),
                (212, "Account", "BalanceAllowanceLimit-LOAN_SECBAL-212"),
                (300, "Bucket", "BalanceAllowanceLimit-DEFAULT-BUCKET"),
                (301, "Account", "BalanceAllowanceLimit-FREE-ACCOUNT"),
                (302, "Bucket", "BalanceAllowanceLimit-Mpesa-FREE"),
                (303, "Account", "BalanceAllowanceLimit-VOICE-FREE"),
            ],
        )
        con.executemany(
            "INSERT INTO BI.REF_PRODUCT VALUES (?, ?)",
            [
                (101, "Inbundle"),
                (102, "Unlimited Bundles"),
                (103, "OOBundle"),
                (104, "Standard"),
            ],
        )

        daily_rows = []
        for day_index, current_day in enumerate(report_days):
            key = day_key(current_day)
            for offset in range(14):
                subscriber = subscribers[(day_index * 7 + offset) % len(subscribers)]
                service_type = "B.VOICE_INC_ONNET" if (day_index + offset) % 19 == 0 else "B.DATA"
                daily_rows.append((subscriber.msisdn, key, service_type))
        con.executemany(
            "INSERT INTO TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS VALUES (?, ?, ?)",
            daily_rows,
        )

        fin_rows = []
        traffic_dates = [20260519, 20260520]
        for current_day in traffic_dates:
            for offset, traffic_type in enumerate((7, 6, 4, 9)):
                subscriber = subscribers[(current_day + offset) % len(subscribers)]
                location_id = subscriber.location_id
                if traffic_type == 7:
                    fin_rows.append(
                        (
                            current_day,
                            subscriber.msisdn,
                            subscriber.id_subscriber,
                            1,
                            7,
                            200,
                            3,
                            230500 + offset * 100,
                            None,
                            230000,
                            500,
                            211,
                            "RECHARGE-APP",
                            location_id,
                        )
                    )
                elif traffic_type == 6:
                    fin_rows.append(
                        (
                            current_day,
                            subscriber.msisdn,
                            subscriber.id_subscriber,
                            1,
                            6,
                            4,
                            None,
                            50000 + offset * 100,
                            250,
                            49500,
                            250,
                            212,
                            "LOAN-APP",
                            location_id,
                        )
                    )
                    fin_rows.append(
                        (
                            current_day,
                            subscriber.msisdn,
                            subscriber.id_subscriber,
                            1,
                            6,
                            28,
                            None,
                            30000 + offset * 100,
                            150,
                            29900,
                            100,
                            212,
                            "OLD-REPAYMENT",
                            location_id,
                        )
                    )
                elif traffic_type == 4:
                    fin_rows.extend(
                        [
                            (
                                current_day,
                                subscriber.msisdn,
                                subscriber.id_subscriber,
                                1,
                                4,
                                100,
                                None,
                                12000 + offset * 100,
                                100,
                                11800,
                                200,
                                211,
                                "PRETUPS-BUNDLE",
                                location_id,
                            ),
                            (
                                current_day,
                                subscriber.msisdn,
                                subscriber.id_subscriber,
                                1,
                                4,
                                100,
                                None,
                                8000 + offset * 100,
                                50,
                                7900,
                                100,
                                303,
                                "CRM-BUNDLE",
                                location_id,
                            ),
                            (
                                current_day,
                                subscriber.msisdn,
                                subscriber.id_subscriber,
                                1,
                                4,
                                100,
                                None,
                                7000 + offset * 100,
                                50,
                                6900,
                                100,
                                303,
                                "CRM-BUNDLE",
                                location_id,
                            ),
                        ]
                    )
                else:
                    fin_rows.append(
                        (
                            current_day,
                            subscriber.msisdn,
                            subscriber.id_subscriber,
                            1,
                            9,
                            274,
                            None,
                            45000 + offset * 100,
                            450,
                            44500,
                            500,
                            211,
                            "REPAYMENT-NEW",
                            location_id,
                        )
                    )
                    fin_rows.append(
                        (
                            current_day,
                            subscriber.msisdn,
                            subscriber.id_subscriber,
                            1,
                            9,
                            273,
                            None,
                            18000 + offset * 100,
                            None,
                            18000,
                            0,
                            212,
                            "REPAYMENT-NEW",
                            location_id,
                        )
                    )
        con.executemany(
            "INSERT INTO BI.FCT_FIN_BLNC_MVMN VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            fin_rows,
        )

        traffic_rows = []
        traffic_template = [
            (101, 101, 1, 1, "J4U_PROMO"),
            (102, 102, 1, 2, "BASE"),
            (103, 103, 2, 3, "BASE"),
            (104, 104, 2, 1, "BASE"),
            (300, 101, 3, 2, "J4U_PROMO"),
            (301, 102, 3, 3, "BASE"),
            (303, 103, 3, 1, "BASE"),
        ]
        for current_day in traffic_dates:
            for offset, (account_id, product_id, traffic_type, roaming_type, info) in enumerate(traffic_template):
                subscriber = subscribers[(current_day + offset * 3) % len(subscribers)]
                traffic_rows.append(
                    (
                        current_day,
                        subscriber.msisdn,
                        subscribers[(current_day + offset * 5 + 1) % len(subscribers)].msisdn,
                        traffic_type,
                        account_id,
                        product_id,
                        subscriber.location_id,
                        120 + offset * 30,
                        roaming_type,
                        info,
                    )
                )
        con.executemany(
            "INSERT INTO BI.FCT_TRAFFIC VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            traffic_rows,
        )


def rewrite_sql(sql_text: str) -> str:
    def replace_date_expression(match: re.Match[str]) -> str:
        report_date = datetime.strptime(match.group("date"), "%Y%m%d").date()
        delta_text = (match.group("delta") or "0").replace(" ", "")
        delta = int(delta_text)
        return str(day_key(report_date + timedelta(days=delta)))

    sql_text = re.sub(r"/\*\+.*?\*/", "", sql_text, flags=re.I | re.S)
    sql_text = re.sub(r"\bNVL\s*\(", "COALESCE(", sql_text, flags=re.I)
    sql_text = re.sub(
        r"to_char\s*\(\s*to_date\(\s*'(?P<date>\d{8})'\s*,\s*'YYYYMMDD'\s*\)\s*(?P<delta>[-+]\s*\d+)?\s*,\s*'YYYYMMDD'\s*\)",
        replace_date_expression,
        sql_text,
        flags=re.I,
    )
    sql_text = re.sub(
        r"to_date\s*\(\s*'(?P<date>\d{8})'\s*,\s*'YYYYMMDD'\s*\)",
        r"\g<date>",
        sql_text,
        flags=re.I,
    )
    
    sql_text = re.sub(
        r"\bWHEN\s+DS_EXEC_REGION\s*=",
        r"WHEN b.DS_EXEC_REGION =",
        sql_text,
        flags=re.I,
    )
    
    return sql_text


def split_statements(sql_text: str) -> list[str]:
    """Split SQL text into individual statements, handling both semicolons and divider comments."""
    lines = sql_text.split("\n")
    statements: list[str] = []
    current_statement: list[str] = []

    for line in lines:
        stripped = line.strip()

        if re.match(r"^-{20,}", stripped):
            if current_statement:
                full_stmt = "\n".join(current_statement).strip()
                if full_stmt and not re.match(r"^-{20,}", full_stmt):
                    statements.append(full_stmt)
                current_statement = []
            continue

        if not stripped or stripped.startswith("--"):
            current_statement.append(line)
            continue

        current_statement.append(line)

        if stripped.endswith(";"):
            full_stmt = "\n".join(current_statement).strip()
            if full_stmt and not re.match(r"^-{20,}", full_stmt):
                statements.append(full_stmt)
            current_statement = []

    if current_statement:
        full_stmt = "\n".join(current_statement).strip()
        if full_stmt and not re.match(r"^-{20,}", full_stmt):
            statements.append(full_stmt)

    return [stmt for stmt in statements if stmt.upper().startswith("SELECT")]


def run_sql(db_path: Path, sql_path: Path, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    sql_text = rewrite_sql(sql_path.read_text(encoding="utf-8-sig"))
    statements = split_statements(sql_text)

    with duckdb.connect(str(db_path)) as con:
        for index, statement in enumerate(statements, start=1):
            cursor = con.execute(statement)
            if cursor.description is None:
                continue

            rows = cursor.fetchall()
            columns = [column[0] for column in cursor.description]
            output_path = output_dir / f"query_{index:02d}.csv"
            with output_path.open("w", newline="", encoding="utf-8") as handle:
                writer = csv.writer(handle)
                writer.writerow(columns)
                writer.writerows(rows)
            print(f"query {index:02d}: {len(rows)} rows -> {output_path}")

    # Auto-generate the pivoted Daily Stand-up Dashboard report
    try:
        from generate_dashboard import generate_dashboard
        generate_dashboard()
    except Exception as e:
        print(f"Warning: Could not auto-generate dashboard report: {e}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build and run a local mock telecom warehouse.")
    parser.add_argument("command", choices=("build", "run"))
    parser.add_argument("--db", default="mock_warehouse.duckdb", help="DuckDB database path")
    parser.add_argument("--sql", default="test2.sql", help="SQL workbook to execute")
    parser.add_argument("--out", default="outputs", help="Output directory for result CSV files")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    db_path = Path(args.db)

    if args.command == "build":
        build_database(db_path)
        print(f"built {db_path}")
        return

    if not db_path.exists():
        build_database(db_path)
    run_sql(db_path, Path(args.sql), Path(args.out))


if __name__ == "__main__":
    main()