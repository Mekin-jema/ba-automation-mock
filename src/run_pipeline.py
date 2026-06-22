#!/usr/bin/env python3
"""Simple command-line runner for the report pipeline."""

from pipeline_service import run_daily_report_job

if __name__ == "__main__":
    run_daily_report_job()
