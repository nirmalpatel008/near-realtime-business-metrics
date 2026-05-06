# Contributing

Thanks for helping improve this learning project.

## Project Goals

This repo is designed for:

- developer education
- portfolio demos
- workshops
- AWS DMS, CDC, analytics, and dashboard tutorials

Prefer changes that make the project clearer, safer, easier to run, or easier to teach.

## Ground Rules

- Do not commit AWS credentials, database passwords, `.env` files, or live RDS endpoints.
- Keep the core DMS demo small and reproducible.
- Put optional extensions behind clear docs or separate scripts.
- Favor explicit runbooks over hidden automation.
- Use synthetic data only.

## Local Setup

Install Python dependencies:

```bash
pip install -r requirements.txt
```

Run the local natural-language assistant in dry-run mode:

```bash
python ai/ask_dashboard.py "How fresh is the dashboard?" --dry-run
```

## Before Opening a PR

Run:

```bash
python -m py_compile ai/ask_dashboard.py
python ai/ask_dashboard.py "Show failed payments by reason" --dry-run
rg -n "AKIA|ASIA|aws_secret_access_key|aws_access_key_id|aws_session_token|AWS_ACCESS_KEY|AWS_SECRET|DB_PASSWORD=|password='|rds.amazonaws.com" .
```

Expected:

- Python compile succeeds.
- Dry-run query matching works.
- Secret scan only returns documentation lines that describe the scan itself.

## Documentation Style

- Keep docs practical and demo-oriented.
- Use placeholders for credentials and endpoints.
- Prefer short command blocks that learners can run.
- Call out cost and teardown steps wherever cloud resources are created.
