# Jenkins Setup Guide

This guide explains how to run the report pipeline from Jenkins instead of a local scheduler.

## 1. Prerequisites

- Jenkins installed and running
- the repository checked out on the Jenkins agent
- a Windows agent if you are using the provided `bat` commands
- Python environment already configured in the repo

## 2. Jenkins pipeline configuration

Create a new Jenkins pipeline job and point it to this repository.

Use the included [Jenkinsfile](Jenkinsfile) as the pipeline definition.

## 3. Important environment settings

Make sure the Jenkins job has access to the same environment variables used by the pipeline:

- `REPORT_RECIPIENTS`
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASSWORD`
- `SMTP_SENDER`
- `REPORT_RUN_HOUR`
- `REPORT_RUN_MINUTE`
- `REPORT_TIMEZONE`

These can be configured in Jenkins under:
- Build Environment / Environment variables, or
- Credentials + inject them into the build.

## 4. Recommended Jenkins triggers

You can schedule the job in Jenkins with a cron-like schedule, for example:

- `H 7 * * *` for daily run at 7:00 AM

## 5. Pipeline behavior

The Jenkins pipeline will:
1. install dependencies,
2. run the report generation pipeline,
3. archive outputs for review.

## 6. Notes

- The pipeline uses the repo's virtual environment (`.venv`) for reliability.
- If your Jenkins agent is Linux, update the shell commands accordingly.
- For Gmail delivery, use an app password for `SMTP_PASSWORD`.
