# How Codex Helped Build This Project

This project started as a focused AWS Summit demo:

```text
RDS MySQL source -> AWS DMS full load + CDC -> RDS MySQL target
```

The original goal was to explain a clear technical idea in 15 minutes:

- full load and CDC can run together
- MySQL binlog changes can be captured continuously
- replication lag can be observed
- multi-table transactions remain consistent

After the summit session, I used Codex to evolve the demo into a broader developer-facing project that could be reused for workshops, articles, portfolio reviews, and videos.

## What Changed

The project grew from a conference demo into a small teaching platform:

- synthetic finance-domain schema
- KPI SQL for DAU, conversion, funnel, payment health, and freshness
- Streamlit dashboard
- optional QuickSight dashboard and topic created through CloudFormation
- safe catalog-backed question runner for "Ask your dashboard"
- optional OpenAI-powered operations brief over bounded KPI outputs
- deployment, teardown, validation, and recording runbooks
- workshop docs, architecture docs, cost notes, and article drafts

## How I Used Codex

Codex was useful across the full lifecycle, not only for code generation:

1. Inspect the existing repo and preserve the working DMS foundation.
2. Propose an incremental extension path instead of redesigning everything.
3. Add schema, scripts, SQL, docs, and dashboard code in small steps.
4. Debug real deployment failures from AWS CLI output, CloudFormation events, and QuickSight errors.
5. Improve the developer experience around setup, secrets, validation, and teardown.
6. Turn the finished build into reusable content: runbooks, article structure, demo scripts, and video flow.

## Examples of Decisions Made During the Build

### Keep the existing architecture

Instead of replacing AWS DMS with a different streaming stack, the project kept DMS as the center of the story and extended around it. That preserved the original teaching goal and made the evolution easier to understand.

### Prefer safe natural-language-style querying

The "Ask your dashboard" path maps questions to approved SQL in `ai/query_catalog.yaml` rather than generating arbitrary SQL. That keeps the demo explainable and avoids giving an unrestricted query surface to the database.

### Make the project runnable for other developers

The repo now includes:

- `.env.example` instead of committed secrets
- `scripts/00-preflight.ps1` for local setup checks
- CloudFormation deploy and teardown scripts
- a GitHub-safe publishing checklist
- a screen-recording runbook with ready-to-run commands

These are small details, but they are the details that decide whether a sample project is only impressive to look at or actually pleasant to use.

### Debug the real system, not an imaginary one

During the build, Codex helped work through failures such as:

- DMS task startup before the source tables were seeded
- QuickSight data-source connectivity timeout
- dataset schema mismatch caused by `payment_ts` vs `event_ts`
- CloudFormation template size limits for QuickSight definitions
- flat DAU caused by reusing the same customers in the live writer

The finished repo contains the fixes, but the developer value came from the iteration: observe, explain, patch, verify.

## Why This Matters for Developer Experience

A useful developer project should do more than work once on the author's machine.

It should:

- teach the core idea clearly
- be reproducible
- make the happy path easy
- expose useful failure modes
- include cost and cleanup guidance
- support multiple learning styles: code, docs, diagrams, demos, and video

That is the standard I tried to move this project toward with Codex.

## Related Materials

- AWS Builder article: [Building Near Real-Time Data Pipelines with AWS DMS: Full Load + CDC](https://builder.aws.com/content/3D1dYOYynMHfhqiIRoEYV89LgSH/building-near-real-time-data-pipelines-with-aws-dms-full-load-cdc)
- Original session video: [YouTube](https://youtu.be/YDKte_7OkqE)
