# QuickSight CloudFormation Guide

This project includes an optional QuickSight extension:

```text
cloudformation/quicksight-mysql.yaml
scripts/deploy-quicksight.sh
```

The extension creates:

- a security group rule from the QuickSight us-east-1 data-source IP range to the target RDS MySQL database
- a QuickSight MySQL data source
- direct-query datasets for overview, funnel, payments, geography, and devices
- a QuickSight dashboard with starter sheets and visuals
- a QuickSight analysis for editable dashboard exploration
- an Amazon Q in QuickSight topic for natural-language KPI questions

QuickSight must already be enabled in the AWS account and Region. This path can
create paid QuickSight resources, especially when Amazon Q topic features are
enabled. Keep Streamlit as the default free-tier-friendly dashboard path.

## Deploy

Deploy the base DMS stack first:

```bash
./scripts/deploy.sh
```

Seed data, start the DMS task, and confirm KPIs work:

```bash
./scripts/start-task.sh
./scripts/12-run-kpis.sh
```

Then deploy QuickSight:

```bash
./scripts/deploy-quicksight.sh
```

Optional: grant a QuickSight user or group access during deployment.

```bash
export QUICKSIGHT_PRINCIPAL_ARN="arn:aws:quicksight:us-east-1:<account-id>:user/default/<username>"
./scripts/deploy-quicksight.sh
```

## Natural-Language Topic

The CloudFormation stack creates a topic named:

```text
Near Real-Time Business Metrics
```

`scripts/deploy-quicksight.sh` grants topic permissions to
`QUICKSIGHT_PRINCIPAL_ARN` after the stack deploys because QuickSight topic
permissions are managed through a separate QuickSight API.

Sample questions:

- How many daily active users do we have?
- What is the conversion rate?
- How fresh is the dashboard?
- Show failed payments by reason.
- Which city has the lowest payment success rate?

## Dashboard

The stack creates a dashboard named:

```text
Near Real-Time Business Metrics
```

Dashboard sheets:

- Executive Overview
- Funnel Analysis
- Payment Reliability
- Segments

The dashboard is intentionally starter-sized so it can be created and deleted
reliably with CloudFormation. It includes table visuals over the generated
datasets and can be refined later in the QuickSight console if needed.

The stack also creates an analysis named:

```text
Near Real-Time Business Metrics Analysis
```

## Teardown

The normal teardown script deletes the QuickSight stack first, including the
temporary QuickSight ingress rule, then deletes the
DMS/RDS stack:

```bash
./scripts/teardown.sh
```

If needed, delete only the QuickSight stack:

```bash
aws cloudformation delete-stack \
  --profile summit-demo \
  --region us-east-1 \
  --stack-name dms-demo-quicksight
```

## Notes

- The QuickSight dashboard is managed by CloudFormation. Manual console edits can
  be overwritten by future stack updates.
- The Streamlit dashboard remains the default runnable demo because it works
  locally and avoids QuickSight/Q costs for learners.
