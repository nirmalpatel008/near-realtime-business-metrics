#!/usr/bin/env python3
"""Generate a structured AI operations brief from dashboard KPI outputs."""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import mysql.connector
from openai import OpenAI
from pydantic import BaseModel, Field


REPO_ROOT = Path(__file__).resolve().parents[1]


def load_dotenv(path: Path = REPO_ROOT / ".env") -> None:
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


@dataclass(frozen=True)
class QuerySpec:
    name: str
    path: str
    limit: int = 5


QUERIES = (
    QuerySpec("freshness", "analytics/queries/freshness.sql"),
    QuerySpec("daily_active_users", "analytics/queries/dau.sql"),
    QuerySpec("conversion_rate", "analytics/queries/conversion_rate.sql"),
    QuerySpec("payment_success_rate", "analytics/queries/payment_success_rate.sql"),
    QuerySpec("failed_payments_by_reason", "analytics/queries/failed_payments_by_reason.sql"),
    QuerySpec("funnel_daily", "analytics/queries/funnel_daily.sql"),
    QuerySpec("geo_segmentation", "analytics/queries/geo_segmentation.sql"),
    QuerySpec("device_segmentation", "analytics/queries/device_segmentation.sql"),
)


class Risk(BaseModel):
    title: str = Field(description="Short risk title.")
    evidence: str = Field(description="Evidence from the supplied KPI snapshot only.")
    severity: str = Field(description="One of: low, medium, high.")


class PipelineBrief(BaseModel):
    headline: str = Field(description="One-sentence executive headline.")
    health_status: str = Field(description="One of: healthy, watch, degraded.")
    summary: list[str] = Field(description="Three concise business observations.")
    risks: list[Risk] = Field(description="Zero to three risks grounded in supplied data.")
    recommended_actions: list[str] = Field(description="Two to four practical next checks.")
    data_freshness_note: str = Field(description="Short note about data freshness.")


def read_sql(relative_path: str) -> str:
    return (REPO_ROOT / relative_path).read_text(encoding="utf-8")


def connection_config(
    host: str | None = None,
    user: str | None = None,
    password: str | None = None,
    database: str | None = None,
    port: int | None = None,
) -> dict[str, Any]:
    load_dotenv()
    config = {
        "host": host or os.getenv("TGT_HOST", ""),
        "user": user or os.getenv("DB_USER", "admin"),
        "password": password or os.getenv("DB_PASSWORD", ""),
        "database": database or os.getenv("DB_NAME", "demo"),
        "port": port or int(os.getenv("DB_PORT", "3306")),
    }
    if not config["host"]:
        raise ValueError("Missing target host. Set TGT_HOST or pass --host.")
    if not config["password"]:
        raise ValueError("Missing database password. Set DB_PASSWORD or pass --password.")
    return config


def rows_as_dicts(cursor: mysql.connector.cursor.MySQLCursor, limit: int) -> list[dict[str, Any]]:
    columns = [column[0] for column in cursor.description or []]
    rows = cursor.fetchmany(limit)
    return [dict(zip(columns, row, strict=True)) for row in rows]


def collect_snapshot(config: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
    snapshot: dict[str, list[dict[str, Any]]] = {}
    conn = mysql.connector.connect(**config)
    try:
        cursor = conn.cursor()
        for spec in QUERIES:
            cursor.execute(read_sql(spec.path))
            snapshot[spec.name] = rows_as_dicts(cursor, spec.limit)
    finally:
        conn.close()
    return snapshot


def generate_brief(snapshot: dict[str, list[dict[str, Any]]], model: str | None = None) -> PipelineBrief:
    load_dotenv()
    client = OpenAI()
    response = client.responses.parse(
        model=model or os.getenv("OPENAI_MODEL", "gpt-5.5"),
        input=[
            {
                "role": "developer",
                "content": (
                    "You are an analytics operations assistant. "
                    "Use only the supplied KPI snapshot. "
                    "Do not invent causes, dates, or trends that are not present. "
                    "Keep the brief concise and suitable for a daily standup."
                ),
            },
            {
                "role": "user",
                "content": (
                    "Create a structured operations brief for this near real-time business metrics pipeline. "
                    f"KPI snapshot JSON:\n{json.dumps(snapshot, default=str)}"
                ),
            },
        ],
        text_format=PipelineBrief,
    )
    return response.output_parsed


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate an OpenAI-powered pipeline operations brief.")
    parser.add_argument("--host", help="Target MySQL host. Defaults to TGT_HOST.")
    parser.add_argument("--port", type=int, help="Target MySQL port. Defaults to DB_PORT or 3306.")
    parser.add_argument("--user", help="Database user. Defaults to DB_USER or admin.")
    parser.add_argument("--password", help="Database password. Defaults to DB_PASSWORD.")
    parser.add_argument("--database", help="Database name. Defaults to DB_NAME or demo.")
    parser.add_argument("--model", help="OpenAI model. Defaults to OPENAI_MODEL or gpt-5.5.")
    parser.add_argument("--snapshot-only", action="store_true", help="Print the KPI snapshot without calling OpenAI.")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        config = connection_config(
            host=args.host,
            user=args.user,
            password=args.password,
            database=args.database,
            port=args.port,
        )
        snapshot = collect_snapshot(config)
        if args.snapshot_only:
            print(json.dumps(snapshot, indent=2, default=str))
            return 0

        brief = generate_brief(snapshot, model=args.model)
        print(brief.model_dump_json(indent=2))
        return 0
    except Exception as exc:
        print(f"ERROR: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
