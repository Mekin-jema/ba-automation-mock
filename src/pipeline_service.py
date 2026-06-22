#!/usr/bin/env python3
"""Reusable pipeline service for report generation and email delivery."""

from __future__ import annotations

import os
import logging
import smtplib
import subprocess
import sys
from email.message import EmailMessage
from pathlib import Path
from typing import Iterable, List

from dotenv import load_dotenv

load_dotenv()

PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = PROJECT_ROOT / "outputs"
REPORT_FILE = OUTPUT_DIR / "real-sample-report-pivoted.csv"
DASHBOARD_FILE = OUTPUT_DIR / "DAILY_REGIONAL_REPORT.xlsx"

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)


def run_command(command: List[str], timeout: int = 180) -> subprocess.CompletedProcess:
    """Run a shell command and raise clear errors if it fails."""
    logger.info("Running: %s", " ".join(command))
    return subprocess.run(command, cwd=PROJECT_ROOT, capture_output=True, text=True, timeout=timeout)


def run_report_pipeline() -> dict:
    """Run the report generation pipeline end to end."""
    steps = [
        [sys.executable, "src/mock_warehouse.py", "build"],
        [sys.executable, "src/mock_warehouse.py", "run"],
        [sys.executable, "src/generate_dashboard.py"],
        [sys.executable, "src/generate_report.py"],
    ]

    results = {}
    for step in steps:
        result = run_command(step)
        results[" ".join(step)] = {
            "returncode": result.returncode,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
        }
        if result.returncode != 0:
            raise RuntimeError(
                f"Pipeline step failed: {' '.join(step)}\nSTDERR:\n{result.stderr}"
            )

    return results


def collect_attachments() -> list[Path]:
    attachments = []
    for path in [REPORT_FILE, DASHBOARD_FILE]:
        if path.exists():
            attachments.append(path)
    return attachments


def send_email(
    recipients: Iterable[str],
    subject: str,
    body: str,
    attachments: Iterable[Path] | None = None,
) -> None:
    """Send email using SMTP settings from environment variables."""
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD")
    sender = os.getenv("SMTP_SENDER", smtp_user)

    if not all([smtp_host, smtp_user, smtp_password, sender]):
        raise RuntimeError(
            "SMTP configuration is incomplete. Please set SMTP_HOST, SMTP_USER, SMTP_PASSWORD, and SMTP_SENDER."
        )

    message = EmailMessage()
    message["Subject"] = subject
    message["From"] = sender
    message["To"] = ", ".join(recipients)
    message.set_content(body)

    for attachment in attachments or []:
        message.add_attachment(
            attachment.read_bytes(),
            maintype="application",
            subtype="octet-stream",
            filename=attachment.name,
        )

    try:
        with smtplib.SMTP(smtp_host, smtp_port) as smtp:
            smtp.starttls()
            smtp.login(smtp_user, smtp_password)
            smtp.send_message(message)
    except smtplib.SMTPAuthenticationError as exc:
        raise RuntimeError(
            f"SMTP authentication failed for {smtp_user}. "
            "For Gmail, use an App Password and confirm the username/password are correct."
        ) from exc
    except smtplib.SMTPException as exc:
        raise RuntimeError(f"SMTP error while sending email: {exc}") from exc

    logger.info("Email sent successfully to %s", ", ".join(recipients))


def run_daily_report_job(recipients: Iterable[str] | None = None) -> dict:
    """Run the pipeline and email the report to the configured recipients."""
    recipients = list(recipients or os.getenv("REPORT_RECIPIENTS", "").split(","))
    recipients = [r.strip() for r in recipients if r.strip()]

    if not recipients:
        raise RuntimeError(
            "No recipients configured. Set REPORT_RECIPIENTS or pass recipients explicitly."
        )

    logger.info("Starting report pipeline...")
    pipeline_results = run_report_pipeline()

    attachments = collect_attachments()
    subject = f"DA report generated - {Path(__file__).resolve().name}"
    body = (
        "Daily automated report is ready.\n\n"
        f"Generated files: {', '.join(a.name for a in attachments)}\n\n"
        f"Pipeline details:\n{pipeline_results}"
    )

    send_email(recipients, subject, body, attachments)

    return {
        "pipeline_results": pipeline_results,
        "attachments": [a.name for a in attachments],
        "recipients": recipients,
    }


if __name__ == "__main__":
    result = run_daily_report_job()
    print(result)
