# Slide Outline & Speaker Notes

**Session:** Building Near Real-Time Data Pipelines with AWS DMS: Aurora to Aurora (Full Load + CDC)
**Duration:** 15 min (≈7 min slides · ≈7 min demo · ≈1 min Q&A)
**Audience:** Data / platform engineers, DBAs, solution architects

Every slide below is mapped to a phrase in the title so the talk demonstrably *delivers the title*.

---

## Slide 1 — Title (0:00–0:20)

**Title:** Building Near Real-Time Data Pipelines with AWS DMS
**Sub:** Aurora → Aurora · Full Load + CDC
**Speaker:** *Your name · AWS Summit BLR 2026*

**Say:** "In the next 15 minutes I'll show you how to stand up a near real-time Aurora-to-Aurora pipeline with AWS DMS — end to end, including a live CDC demo with sub-5-second lag."

---

## Slide 2 — Why this talk? (0:20–1:20) · *delivers "Near Real-Time Data Pipelines"*

**Headline:** Batch ETL is dying. Streaming replication is the new baseline.

**Three bullets:**
- **Reporting can't wait 24 hours** — dashboards, fraud, personalization need < 1-min data
- **Cutovers must be zero-downtime** — DR, cross-account, version upgrades
- **Point solutions are fragile** — triggers, custom binlog readers, bespoke Lambdas don't scale

**Say:** "Near real-time means *seconds, not hours*. That changes everything about how you design the pipeline — you need a managed CDC engine, not a cron job."

---

## Slide 3 — What is AWS DMS? (1:20–2:20) · *delivers "AWS DMS"*

**Headline:** DMS = managed replication engine for databases

**Four bullets:**
- **Heterogeneous or homogeneous** — Oracle→Postgres, MySQL→MySQL, RDBMS→S3/Kinesis/Kafka
- **Two phases in one task**: Full Load (snapshot) + CDC (change stream)
- **Serverless or provisioned** replication instances
- **Fully managed** — no agents, no binlog parser code, no state store to babysit

**Say:** "DMS is the replication instance *plus* the schema converter *plus* the binlog reader, all behind one API. You give it two endpoints, it moves rows."

---

## Slide 4 — Architecture (2:20–3:20) · *the title diagram*

**Use the architecture image the user already made** (Aurora → DMS RI → Aurora).

**Callouts to hit verbally:**
- **Source prereqs:** `binlog_format=ROW`, retention ≥ 24h, replication user with `REPLICATION SLAVE` + `SELECT`
- **DMS RI:** lives in the same VPC, not on public internet
- **Target:** empty schema is fine — DMS creates tables during full load

**Say:** "Everything in one VPC, KMS-encrypted, private endpoints. This whole diagram is one CloudFormation template you'll see in a minute."

---

## Slide 5 — Why Aurora → Aurora? (3:20–4:00) · *delivers "Aurora to Aurora"*

**Headline:** Homogeneous, but still a real use case

**Four bullets:**
- **Reporting replica** — isolate analytical load from OLTP
- **Cross-account / cross-region DR** — physical replicas can't cross accounts; DMS can
- **Blue/green upgrades** — move from Aurora MySQL 5.7 → 8.0 with <5s lag, then cut over
- **Aurora → data warehouse feed** — same pattern, swap target for Redshift/S3

**Say:** "People assume DMS is only for migrations *off* a platform. Aurora-to-Aurora is one of its most common production patterns."

---

## Slide 6 — Full Load phase (4:00–4:45) · *delivers "Full Load"*

**Headline:** Phase 1 — consistent snapshot, in parallel

**Four bullets:**
- Parallel table scans (`MaxFullLoadSubTasks`, default 8)
- Creates target tables (`DROP_AND_CREATE` / `TRUNCATE` / `DO_NOTHING`)
- **Buffers CDC events during load** — no lost changes
- Committed at table granularity → progress visible per-table

**Say:** "Full load is a bulk `SELECT *` per table, applied in parallel. While it runs, DMS is already reading the binlog and buffering — the cutover to CDC is seamless."

---

## Slide 7 — CDC phase (4:45–5:30) · *delivers "CDC" + "Near Real-Time"*

**Headline:** Phase 2 — binlog tail, row-level apply

**Four bullets:**
- Reads MySQL binlog (`ROW` format) from the LSN captured at full-load start
- Applies `INSERT` / `UPDATE` / `DELETE` on target
- `BatchApplyEnabled: true` → groups changes, keeps lag low under load
- **Typical lag: < 5 seconds** on `dms.t3.medium`

**Say:** "This is the 'near real-time' promise. Source commit → target commit in under five seconds, all day."

---

## Slide 8 — Live Demo (5:30–12:30) · *the title, proven*

**On screen during demo — persistent sidebar:**
- Source: `<source-endpoint>`
- Target: `<target-endpoint>`
- DMS task: `dms-demo-task`

**Demo beats (scripted in `README.md`):**
1. Show CFN stack already deployed (`describe-stacks`)
2. Seed source — 1k customers, 5k orders (`01-seed-source.sql`)
3. Start task (`./scripts/start-task.sh`)
4. Show DMS console → Table stats → rows flowing
5. Verify target counts match (`03-verify-target.sql`)
6. **Money shot:** side-by-side terminals, run `02-cdc-demo.sql` on source, re-query target → rows appear in ~2s
7. Point at CloudWatch: `CDCLatencyTarget` metric

**Fallback:** If network dies, have a pre-recorded 30s screencast ready.

---

## Slide 9 — Production gotchas (12:30–13:30)

**Headline:** Things the docs hide in footnotes

**Five bullets:**
- **Primary keys are mandatory** for efficient CDC — no PK = full row compare = slow
- **DDL replication is limited** — most ALTERs replicate, some (e.g. `RENAME`) don't
- **LOB handling** — `LimitedSizeLobMode` is fast, `FullLobMode` is correct; pick per table
- **Binlog retention ≥ 24h** — if DMS falls behind beyond retention, resync required
- **Monitor `CDCLatencySource` AND `CDCLatencyTarget`** — they diagnose different problems

---

## Slide 10 — Scaling & cost (13:30–14:00)

**Headline:** Sizing cheat sheet

| Workload | RI class | Notes |
|---|---|---|
| Demo / dev | `dms.t3.medium` | burst, ~$0.10/hr |
| <10k TPS | `dms.c6i.large` | steady, `BatchApplyEnabled` |
| >50k TPS | `dms.c6i.2xlarge` + MultiAZ | multiple parallel CDC tasks by schema |

**Serverless DMS:** good for spiky or intermittent pipelines; not for steady high-throughput CDC.

---

## Slide 11 — Takeaways (14:00–14:30)

- **DMS = managed CDC**, not just a migration tool
- **Full Load + CDC in one task** = zero-data-loss cutovers
- **Near real-time on Aurora** costs ~$0.10/hr to prototype — no excuse not to try it
- **Infra is boring** — one CFN template, reusable across accounts

---

## Slide 12 — Q&A / Resources (14:30–15:00)

- GitHub: *(your repo with this CFN + scripts)*
- AWS DMS User Guide → "Using MySQL as a source"
- Aurora cluster parameter group reference
- `@your-handle` for follow-ups

---

## Timing contract

| Mark | Slide | What must be on screen |
|------|-------|-------------------------|
| 0:00 | 1 | Title |
| 3:00 | 4 | Architecture |
| 5:30 | 8 | Terminal + DMS console |
| 12:30 | 9 | Gotchas |
| 14:30 | 12 | Q&A |

If the demo runs long, **cut slide 10**. Never cut slide 9 (gotchas are what make you credible).
