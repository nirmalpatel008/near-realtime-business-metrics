# Why the Demo Runs on RDS MySQL, Not Aurora

**TL;DR** — On the new AWS **Free Plan** (default for all new AWS accounts since Jul 2025),
Aurora clusters can only be created in a mode called **Express Configuration**, which is
architecturally incompatible with AWS DMS. RDS MySQL has none of these restrictions and
tells exactly the same CDC story.

---

## The three blockers, in order

### 1. Free-plan Aurora requires `WithExpressConfiguration=true`

When a Free-Plan account calls the RDS API to create an Aurora cluster, AWS forces the
request to include a flag called `WithExpressConfiguration=true`. Without it, the API
returns:

> *"To use Aurora clusters with free plan accounts you need to set WithExpressConfiguration."*

- **Console**: sets the flag silently for you
- **AWS CLI**: supports `--with-express-configuration`
- **CloudFormation `AWS::RDS::DBCluster`**: **no property exists** for this flag today

→ **Every `aws cloudformation deploy` attempt fails** on a Free-Plan account. This alone
rules out Infrastructure-as-Code for the demo.

### 2. Express Aurora clusters have no VPC

Quoting the AWS docs
([Create with express configuration — Limitations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_GettingStartedAurora.AuroraPostgreSQL.ExpressConfig.html)):

> *"You cannot associate express clusters with an Amazon Virtual Private Cloud (VPC).
> Clusters with express configuration reside outside a VPC network and include an
> internet access gateway."*

But:
- DMS replication instances **must** be launched inside a VPC
- DMS reaches the source / target DB over that VPC

→ Even if we created the Aurora cluster via CLI as a workaround, **DMS cannot connect to
it**. The DMS endpoint connection test would fail. This is an architectural incompatibility,
not a config issue.

### 3. Express Aurora forces IAM-auth-only

> *"You can only use RDS IAM authentication with the internet access gateway… managed
> credentials in Secrets Manager cannot be used. You also cannot disable IAM authentication."*

DMS endpoints in our demo use a static username/password. Switching to IAM auth would mean:
- Generating 15-minute rotating IAM DB auth tokens
- A `ServiceAccessRoleArn` on every DMS endpoint with `rds-db:connect` permission
- Rewriting all seed / client scripts to use `aws rds generate-db-auth-token`

Doable but adds ~1 hour of work and 4 new things that can fail on stage.

### Minor additional limitations
- Cannot select a specific engine version at create time
- Cannot use a custom DB parameter group at create time (can only modify after create + reboot)
- Encryption is locked to the AWS-managed KMS key (no CMK)
- No Aurora Global Database, RDS Proxy, Zero-ETL, Blue/Green, Data API at create time
- IPv4 only

---

## Why this isn't an AWS bug

Express Configuration is intentional — it's a **zero-cost safety net** for brand-new
accounts so beginners don't accidentally spin up a multi-AZ Aurora Global Database with
a $2000/month bill on day 1. Free-plan accounts trade flexibility for guardrails.

It just happens that a DMS-based demo requires precisely the flexibility Express
Configuration removes (VPC networking, custom parameter groups for `binlog_format=ROW`,
password auth).

---

## Why RDS MySQL is the right pivot, not a compromise

The talk is titled *Near Real-Time Data Pipelines with AWS DMS: Aurora to Aurora*,
but the *demo story* is about **DMS Full Load + CDC** — the DMS replication engine
is identical regardless of the source/target engine.

| Concept on stage | Demonstrated identically on RDS MySQL? |
|---|---|
| Binlog as the CDC contract (`binlog_format=ROW`, retention ≥ 24h) | ✅ Yes — same `SHOW VARIABLES` output, same params |
| Full Load phase (bulk snapshot) | ✅ Same `aws dms describe-replication-tasks` fields |
| CDC phase streaming `INSERT/UPDATE/DELETE` | ✅ Same DMS endpoint, same `EngineName: mysql` in config |
| Transactional consistency (multi-table atomic commit) | ✅ Same |
| CloudWatch `CDCLatencyTarget` metric | ✅ Same metric, same namespace |
| Sub-second lag with `dms.c6i.large` + `BatchApplyEnabled` | ✅ Same tuning dials |

What Aurora-specific storage or cluster-level features we'd normally mention:
- *"Aurora distributes across 6 storage nodes"* — irrelevant to DMS; DMS only reads the binlog
- *"Aurora readers scale independently"* — irrelevant; DMS always reads from the writer
- *"Aurora engine version = `aurora-mysql`"* — one dropdown value difference in the DMS endpoint

**One slide disclaimer covers it:**

> *"This demo runs on RDS MySQL for account-plan reasons. The DMS configuration for
> Aurora MySQL is identical — just change `EngineName: mysql` to `EngineName: aurora-mysql`
> in the endpoint. Everything else is byte-for-byte the same."*

---

## If you want Aurora back later

Three paths, all outside Free Plan:

1. **Upgrade the AWS account to paid** (one click in Billing Console; still pay-per-use,
   you only pay for hours actually used).
2. **Use a separate AWS account** already on the paid plan.
3. **Change the demo to be 100% console-clicked** (no CFN, no CLI) — possible, but loses
   the "reproducible IaC" story and makes rehearsal painful.

For this session we picked: **RDS MySQL, deployed via CloudFormation, reproducible in 12 min
on any AWS account**. Which is actually a *better* IaC story than the original Aurora plan.
