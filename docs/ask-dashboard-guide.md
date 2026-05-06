# Ask Your Dashboard Guide

This is the local question runner for the KPI layer.

It does not generate arbitrary SQL. It maps a question to one approved query in:

```text
ai/query_catalog.yaml
```

Then it runs the associated SQL file from:

```text
analytics/queries/
```

## Why This Exists

QuickSight plus Amazon Q is the AWS-native path. The local runner is the lower-friction path for demos and workshops:

- works without enabling QuickSight
- keeps SQL inspectable
- is easy to explain in workshops
- avoids open-ended SQL generation

## Install

From the repo root:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

On Windows PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## List Supported Questions

```bash
python ai/ask_dashboard.py --list
```

## Dry Run

Use dry-run mode to test question matching without connecting to MySQL:

```bash
python ai/ask_dashboard.py "What was DAU yesterday?" --dry-run
```

Expected behavior:

- prints the matched query ID
- prints the SQL file
- prints the matched SQL
- does not connect to the database

## Run Against the DMS Target

Set target connection details:

```bash
export TGT_HOST=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --stack-name dms-demo \
  --query "Stacks[0].Outputs[?OutputKey=='TargetEndpointAddress'].OutputValue" --output text)
export DB_PASSWORD='<set-a-strong-demo-password>'
```

Ask a question:

```bash
python ai/ask_dashboard.py "Which city had the lowest payment success rate?"
```

You can also pass connection details directly:

```bash
python ai/ask_dashboard.py "How fresh is the dashboard?" \
  --host "$TGT_HOST" \
  --user admin \
  --password "$DB_PASSWORD" \
  --database demo
```

## Demo Questions

```text
What was DAU yesterday?
What was the conversion rate yesterday?
Show failed payments by reason.
Which city had the lowest payment success rate?
Compare mobile and web conversion.
How fresh is the dashboard?
Where are users dropping off?
```

## How Matching Works

The CLI uses transparent keyword matching:

```text
user question
  -> tokenize question
  -> compare against query ID, description, examples, and keyword hints
  -> select highest scoring approved query
  -> run approved SQL file
```

This is intentionally simple. In a workshop, it is much easier to trust a catalog-backed query than a black-box SQL generator.

## Extension Ideas

After the safe catalog path works, you can add:

- LLM-generated summaries over query results
- semantic matching using embeddings
- Amazon Bedrock or OpenAI summary provider
- role-based query permissions
- chart suggestions

Keep SQL execution catalog-based unless you explicitly want to demonstrate SQL generation guardrails.
