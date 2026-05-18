# OpenAI Operations Brief Guide

The optional OpenAI-native extension turns existing KPI outputs into a concise operations brief.

It reads the same approved SQL metrics already used by the dashboard:

- freshness
- DAU
- conversion rate
- payment success
- failed-payment reasons
- funnel
- geography
- devices

Then it sends only that bounded KPI snapshot to the OpenAI API and requests a structured response:

- headline
- health status
- summary
- risks
- recommended actions
- freshness note

This keeps the feature useful without giving the model arbitrary database access.

## Setup

Install dependencies:

```powershell
python -m pip install -r requirements.txt
```

Add these values to local `.env`:

```text
OPENAI_API_KEY=<your-openai-api-key>
OPENAI_MODEL=gpt-5.5
```

Do not commit `.env`.

## CLI Usage

Inspect the exact KPI snapshot without calling the API:

```bash
python ai/openai_ops_brief.py --snapshot-only
```

Generate a structured brief:

```bash
python ai/openai_ops_brief.py
```

## Streamlit Usage

Run the dashboard:

```powershell
python -m streamlit run dashboard/app.py
```

Open the `AI Brief` tab and click `Generate AI brief`.

## Why This Design

- It uses existing project metrics rather than inventing new data paths.
- It demonstrates the OpenAI Responses API in a practical developer workflow.
- It uses structured output so downstream UI code receives predictable fields.
- It limits the model input to approved KPI results, which keeps the feature easier to reason about and safer to demo.
