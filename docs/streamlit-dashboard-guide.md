# Streamlit Dashboard Guide

The Streamlit dashboard is the fastest way to show the KPI layer in a browser.
It reads from the DMS target database and uses the same SQL files as the CLI.

The dashboard also includes an **Ask Your Dashboard** tab. That tab uses
`ai/query_catalog.yaml` and `ai/ask_dashboard.py` to match business questions to
approved SQL. It does not generate arbitrary SQL.

## Prerequisites

Deploy the AWS stack, seed the finance schema, and start the DMS task first.

Install local Python dependencies:

```powershell
python -m pip install -r requirements.txt
```

Set local connection values in `.env`:

```text
DB_USER=admin
DB_NAME=demo
DB_PASSWORD=<your-demo-password>
TGT_HOST=<target-rds-endpoint>
```

Do not commit `.env`.

## Run

From the repo root:

```powershell
python -m streamlit run dashboard/app.py
```

Open:

```text
http://localhost:8501
```

## Tabs

- **Overview**: DAU, conversion, payment success, gross transaction value,
  freshness, recent transactions, and failed payments.
- **Funnel**: login, merchant view, payment start, payment success, and purchase
  completion.
- **Segments**: city, geography, device, OS, and channel cuts.
- **Ask**: natural-language-style KPI questions backed by approved SQL.
- **Data**: raw KPI outputs for validation and workshop walkthroughs.

## Demo Tip

Keep the live writer running in a separate Git Bash terminal:

```bash
./scripts/11-generate-live-finance-events.sh
```

Refresh the Streamlit page to show new rows, freshness, and KPI changes.
