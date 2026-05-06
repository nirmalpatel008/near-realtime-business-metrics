# Cost Guide

This project can create billable AWS resources. Keep the demo short, use small resources, and tear everything down after use.

## Current Stack

The current CloudFormation stack creates:

- two RDS MySQL instances
- one DMS replication instance
- storage for RDS and DMS
- VPC networking resources
- CloudWatch logs and metrics

The stack is designed for demos, not production. Run:

```bash
./scripts/teardown.sh
```

after every rehearsal or live session.

## Free-Tier-Friendly Defaults

Recommended defaults:

- use `db.t3.micro` or the smallest eligible RDS MySQL class available in your account
- use the smallest DMS instance that can support the demo
- keep data volumes small
- avoid NAT Gateways
- keep Redshift, QuickSight, Glue, and long-running resources optional
- create a billing alarm before running workshops
- use QuickSight screenshots or a recorded demo for public workshops unless you intentionally want each participant to enable QuickSight

## Low-Cost Development Path

Use this order:

1. DMS plus RDS for the core CDC demo.
2. SQL-only KPI queries on the target database.
3. Local dashboard using exported CSV or a lightweight Streamlit app.
4. Optional S3 raw layer.
5. Optional QuickSight or Redshift only when you need the AWS-native dashboard path.

## Workshop Cost Guidance

For learners:

- provide a local/no-cloud path where possible
- make cloud deployment optional
- tell participants to tear down immediately
- include the teardown command in every workshop module

## Cost-Safe Storytelling

It is fine for the portfolio project to show a target AWS architecture while implementing only the lowest-cost path first. Be explicit:

```text
MVP: RDS + DMS + SQL KPI queries
Optional: S3 + Glue + QuickSight + Redshift
```

## QuickSight and Natural Language Cost Note

QuickSight and Amazon Q in QuickSight are useful for a conference or portfolio walkthrough, but they are not required for the core demo. Treat them as the AWS-native dashboard path:

```text
Core: DMS + RDS + KPI SQL
Optional: QuickSight dashboard + Amazon Q questions
```

For cost-sensitive demos, use screenshots from `quicksight/screenshots/` after you build the dashboard once.
