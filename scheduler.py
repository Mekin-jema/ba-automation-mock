#!/usr/bin/env python3
"""Scheduler for daily automated report delivery."""

from __future__ import annotations

import os
from apscheduler.schedulers.blocking import BlockingScheduler
from pipeline_service import run_daily_report_job


def main() -> None:
    scheduler = BlockingScheduler()
    scheduler.add_job(
        run_daily_report_job,
        trigger="cron",
        hour=int(os.getenv("REPORT_RUN_HOUR", "7")),
        minute=int(os.getenv("REPORT_RUN_MINUTE", "0")),
        timezone=os.getenv("REPORT_TIMEZONE", "UTC"),
        args=[os.getenv("REPORT_RECIPIENTS", "").split(",")],
    )
    print("Scheduler started. Daily job configured.")
    scheduler.start()


if __name__ == "__main__":
    main()
