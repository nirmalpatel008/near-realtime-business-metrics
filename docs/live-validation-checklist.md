# Live Validation Checklist

Use this checklist before running the portfolio demo against AWS.

## Required Local Tools

- Python 3
- AWS CLI v2
- MySQL client
- Bash, Git Bash, WSL, CloudShell, or a Linux terminal for `.sh` scripts

Windows preflight:

```powershell
.\scripts\00-preflight.ps1
```

If PowerShell blocks local scripts, run it for this process only:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\00-preflight.ps1
```

If you already know the current endpoints:

```powershell
$env:SRC_HOST="your-source-endpoint"
$env:TGT_HOST="your-target-endpoint"
.\scripts\00-preflight.ps1
```

## Required Environment

```bash
export AWS_PROFILE=summit-demo
export AWS_REGION=us-east-1
export DB_PASSWORD='<set-a-strong-demo-password>'
```

Resolve endpoints from CloudFormation:

```bash
export SRC_HOST=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --stack-name dms-demo \
  --query "Stacks[0].Outputs[?OutputKey=='SourceEndpointAddress'].OutputValue" --output text)

export TGT_HOST=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --stack-name dms-demo \
  --query "Stacks[0].Outputs[?OutputKey=='TargetEndpointAddress'].OutputValue" --output text)
```

## Validation Path

Seed source:

```bash
mysql -h "$SRC_HOST" -u admin -p"$DB_PASSWORD" demo < scripts/10-seed-finance-source.sql
```

Start DMS:

```bash
./scripts/start-task.sh
watch -n2 ./scripts/status.sh
```

Generate live events:

```bash
./scripts/11-generate-live-finance-events.sh
```

Watch finance lag:

```bash
./scripts/13-measure-finance-lag.sh
```

Run KPIs:

```bash
./scripts/12-run-kpis.sh
```

Ask dashboard:

```bash
python ai/ask_dashboard.py "How fresh is the dashboard?" --host "$TGT_HOST" --password "$DB_PASSWORD"
python ai/ask_dashboard.py "Show failed payments by reason" --host "$TGT_HOST" --password "$DB_PASSWORD"
```

## Known Blockers

- If `aws` is not found, install AWS CLI v2 and configure the profile.
- If `mysql` is not found, install MySQL client or run from AWS CloudShell.
- If old RDS endpoints do not resolve, the stack was probably deleted or rebuilt. Resolve fresh endpoints from CloudFormation outputs.
- If source/target connectivity fails, check the stack security group and current laptop public IP allowlist.
