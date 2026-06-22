# Pipeline-Only Automation Guide

This guide shows how to run the reporting workflow without any web interface.
It will:
- run the report pipeline from the terminal,
- send the report to the responsible team by email,
- run automatically every morning if you enable the scheduler.

## 1. What will be used

- `run_pipeline.py` — command-line entry point for manual runs
- `pipeline_service.py` — reusable logic to build reports, generate outputs, and send emails
- `scheduler.py` — optional scheduled runner for daily automation
- environment settings for SMTP and report recipients

## 2. Install dependencies

Run:

```bash
pip install -r requirements.txt
```

The updated requirements include:
- Flask
- APScheduler
- python-dotenv

## 3. Configure environment variables

Copy the example file and update values:

```bash
copy .env.example .env
```

Example values:

```env
REPORT_RECIPIENTS=team1@example.com,team2@example.com
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=your_email@example.com
SMTP_PASSWORD=your_password
SMTP_SENDER=your_email@example.com
REPORT_RUN_HOUR=7
REPORT_RUN_MINUTE=0
REPORT_TIMEZONE=Africa/Addis_Ababa
```

> Use an app password if your email provider requires one.

## 4. Run the pipeline manually from the terminal

Use the command-line runner:

```bash
python run_pipeline.py
```

This will:
1. build the database,
2. execute SQL queries,
3. generate the dashboard,
4. generate the report,
5. email the results.

If you prefer, you can also run the service directly:

```bash
python pipeline_service.py
```

## 5. Schedule the pipeline every morning

Start the scheduler:

```bash
python scheduler.py
```

The scheduler is configured to run at the time set in `.env`.

## 6. Recommended cool features to add next

- dashboard summary page with last run time and status
- report history table showing previous runs
- checkbox to choose which outputs to attach
- preview of the generated CSV/Excel files in the browser
- log viewer for each run
- retry logic if email delivery fails
- role-based access so only authorized staff can trigger reports
- a downloadable PDF/HTML summary for executives

## 7. Suggested workflow

1. Developer updates the SQL logic or report template.
2. Web UI is used for one-off runs during testing.
3. Scheduler runs daily at the configured time.
4. Responsible team receives the report via email.
5. Team checks outputs in the shared folder or the web dashboard.

## 8. Troubleshooting

- `ModuleNotFoundError` → run `pip install -r requirements.txt`
- email not sent → verify SMTP credentials and app password
- outputs not created → run `python mock_warehouse.py build` and `python mock_warehouse.py run`
- scheduler not running → check that the terminal stays open or use a Windows service / Task Scheduler

## 9. Optional production deployment ideas

- deploy the web app on Render, Railway, Azure App Service, or a local server,
- use a real database for storing run history,
- store logs in a file or database,
- add authentication for secure access.
