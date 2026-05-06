# Architecture Diagrams

These diagrams are written in Mermaid so they render directly on GitHub.

## Current Runnable DMS Demo

```mermaid
flowchart LR
  App[Live write generator] --> Source[(RDS MySQL source)]
  Source --> Binlog[MySQL binlog ROW events]
  Binlog --> DMS[AWS DMS replication instance]
  DMS --> Target[(RDS MySQL target)]
  Target --> Checks[SQL lag and integrity checks]
  DMS --> CloudWatch[CloudWatch DMS latency metrics]
```

## Full Load Plus CDC

```mermaid
sequenceDiagram
  participant Source as RDS MySQL Source
  participant DMS as AWS DMS Task
  participant Target as RDS MySQL Target
  participant Writer as Live Writer

  DMS->>Source: Start full load snapshot
  DMS->>Target: Create/copy tables
  Writer->>Source: Insert/update live rows
  Source-->>DMS: Binlog events captured during full load
  DMS->>Target: Finish full load
  DMS->>Target: Apply buffered CDC events
  DMS->>Target: Continue streaming new changes
```

## Portfolio Analytics Platform

```mermaid
flowchart LR
  Source[(Operational RDS MySQL)]
  DMS[AWS DMS CDC]
  Raw[(S3 raw layer)]
  Transform[Python or AWS Glue transformations]
  Analytics[(Analytics layer: RDS, Athena, or Redshift)]
  Dashboard[QuickSight or Streamlit dashboard]
  Query[Ask your dashboard]

  Source --> DMS
  DMS --> Raw
  Raw --> Transform
  Transform --> Analytics
  Analytics --> Dashboard
  Analytics --> Query
```

## Finance/Product Data Model

```mermaid
erDiagram
  REGIONS ||--o{ CUSTOMERS : contains
  CUSTOMERS ||--o{ ACCOUNTS : owns
  CUSTOMERS ||--o{ DEVICES : uses
  REGIONS ||--o{ MERCHANTS : hosts
  CUSTOMERS ||--o{ TRANSACTIONS : makes
  MERCHANTS ||--o{ TRANSACTIONS : receives
  TRANSACTIONS ||--o{ PAYMENTS : attempts
  CUSTOMERS ||--o{ USER_EVENTS : generates
  DEVICES ||--o{ USER_EVENTS : emits
  MERCHANTS ||--o{ USER_EVENTS : appears_in
  TRANSACTIONS ||--o{ USER_EVENTS : relates_to
```

## QuickSight and Natural Language Path

```mermaid
flowchart LR
  Analytics[(Curated KPI tables/views)]
  Dataset[QuickSight datasets]
  Dashboard[QuickSight dashboard]
  Topic[Amazon Q in QuickSight topic]
  User[Business user question]
  LocalQuery[Local query catalog runner]

  Analytics --> Dataset
  Dataset --> Dashboard
  Dataset --> Topic
  User --> Topic
  Topic --> Dashboard
  User --> LocalQuery
  LocalQuery --> Analytics
```

## Observability Loop

```mermaid
flowchart TD
  DMS[AWS DMS task]
  CloudWatch[CloudWatch metrics]
  Lag[Source-to-target lag query]
  Freshness[Dashboard freshness query]
  Reconcile[Source/target reconciliation]
  Runbook[Demo and operations runbooks]

  DMS --> CloudWatch
  DMS --> Lag
  Lag --> Freshness
  Freshness --> Runbook
  Reconcile --> Runbook
  CloudWatch --> Runbook
```
