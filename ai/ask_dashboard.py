#!/usr/bin/env python3
"""Ask approved KPI questions against the analytics target.

This is a deliberately lightweight natural-language interface. It does not
generate arbitrary SQL. It maps a user question to an approved query in
ai/query_catalog.yaml, runs that SQL file, and prints the result.
"""

from __future__ import annotations

import argparse
import csv
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import mysql.connector
import yaml


REPO_ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = REPO_ROOT / "ai" / "query_catalog.yaml"


STOPWORDS = {
    "a",
    "about",
    "an",
    "and",
    "are",
    "by",
    "did",
    "do",
    "for",
    "had",
    "has",
    "have",
    "how",
    "in",
    "is",
    "last",
    "me",
    "most",
    "of",
    "on",
    "show",
    "the",
    "this",
    "to",
    "was",
    "week",
    "what",
    "when",
    "where",
    "which",
    "with",
}


KEYWORD_HINTS = {
    "daily_active_users": {"dau", "active", "users", "user"},
    "conversion_rate": {"conversion", "convert", "purchase", "completed"},
    "payment_success_rate": {"payment", "success", "reliability", "attempts"},
    "failed_payments_by_reason": {"failed", "failure", "failures", "reason", "payments", "error", "cause"},
    "funnel_daily": {"funnel", "drop", "dropping", "sessions", "login"},
    "geo_segmentation": {"city", "cities", "region", "regions", "geo", "geography", "location"},
    "device_segmentation": {"device", "devices", "android", "ios", "os", "mobile", "web", "tablet"},
    "freshness": {"fresh", "freshness", "lag", "delay", "delayed", "latest", "pipeline"},
}


def load_dotenv(path: Path = REPO_ROOT / ".env") -> None:
    if not path.exists():
        return

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


@dataclass
class CatalogQuery:
    query_id: str
    description: str
    sql_file: Path
    example_questions: list[str]


@dataclass
class MatchResult:
    query: CatalogQuery
    score: int
    matched_terms: list[str]


def tokenize(text: str) -> set[str]:
    words = re.findall(r"[a-z0-9_]+", text.lower())
    normalized: set[str] = set()
    for word in words:
        if word in STOPWORDS:
            continue
        normalized.add(word)
        if word.endswith("s") and not word.endswith("ss") and len(word) > 3:
            normalized.add(word[:-1])
    return normalized


def load_catalog(path: Path = CATALOG_PATH) -> list[CatalogQuery]:
    with path.open("r", encoding="utf-8") as handle:
        raw = yaml.safe_load(handle)

    queries = []
    for query_id, item in raw.get("queries", {}).items():
        queries.append(
            CatalogQuery(
                query_id=query_id,
                description=item["description"],
                sql_file=REPO_ROOT / item["sql_file"],
                example_questions=item.get("example_questions", []),
            )
        )
    return queries


def match_question(question: str, queries: list[CatalogQuery]) -> MatchResult:
    question_terms = tokenize(question)
    best: MatchResult | None = None

    for query in queries:
        query_terms = tokenize(query.query_id.replace("_", " "))
        query_terms.update(tokenize(query.description))
        for example in query.example_questions:
            query_terms.update(tokenize(example))
        query_terms.update(KEYWORD_HINTS.get(query.query_id, set()))

        matched_terms = sorted(question_terms & query_terms)
        score = len(matched_terms)

        if best is None or score > best.score:
            best = MatchResult(query=query, score=score, matched_terms=matched_terms)

    if best is None or best.score == 0:
        raise ValueError("No matching KPI query found. Try --list to see supported questions.")

    return best


def get_connection(args: argparse.Namespace) -> mysql.connector.MySQLConnection:
    load_dotenv()
    host = args.host or os.getenv("TGT_HOST")
    password = args.password or os.getenv("DB_PASSWORD")
    user = args.user or os.getenv("DB_USER", "admin")
    database = args.database or os.getenv("DB_NAME", "demo")
    port = args.port

    if not host:
        raise ValueError("Missing target host. Pass --host or set TGT_HOST.")
    if not password:
        raise ValueError("Missing database password. Pass --password or set DB_PASSWORD.")

    return mysql.connector.connect(
        host=host,
        port=port,
        user=user,
        password=password,
        database=database,
    )


def read_sql(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def run_query(sql: str, args: argparse.Namespace) -> tuple[list[str], list[tuple[Any, ...]]]:
    conn = get_connection(args)
    try:
        cursor = conn.cursor()
        cursor.execute(sql)
        rows = cursor.fetchmany(args.limit)
        columns = [column[0] for column in cursor.description or []]
        return columns, rows
    finally:
        conn.close()


def print_table(columns: list[str], rows: list[tuple[Any, ...]]) -> None:
    if not columns:
        print("No result columns returned.")
        return

    output = csv.writer(sys.stdout)
    output.writerow(columns)
    for row in rows:
        output.writerow(row)


def summarize(match: MatchResult, row_count: int) -> str:
    query_id = match.query.query_id
    if query_id == "daily_active_users":
        return "This answers user engagement over time. Use it as the top-level product activity metric."
    if query_id == "conversion_rate":
        return "This compares users who logged in with users who completed purchases."
    if query_id == "payment_success_rate":
        return "This shows payment reliability across attempts. Watch for drops before demos and dashboards."
    if query_id == "failed_payments_by_reason":
        return "This shows why payments are failing. Use it to identify operational or product segments to investigate."
    if query_id == "funnel_daily":
        return "This shows step-by-step session movement through the product funnel."
    if query_id == "geo_segmentation":
        return "This highlights city-level differences in active users and payment health."
    if query_id == "device_segmentation":
        return "This helps compare conversion and payment reliability by device and operating system."
    if query_id == "freshness":
        return "This shows how current the replicated data is. Freshness is the dashboard trust metric."
    return f"Returned {row_count} row(s) for the matched KPI query."


def list_queries(queries: list[CatalogQuery]) -> None:
    for query in queries:
        print(f"{query.query_id}: {query.description}")
        for example in query.example_questions:
            print(f"  - {example}")
        print()


def build_parser() -> argparse.ArgumentParser:
    load_dotenv()
    parser = argparse.ArgumentParser(
        description="Ask natural-language KPI questions using the approved query catalog."
    )
    parser.add_argument("question", nargs="*", help="Question to ask, for example: What was DAU yesterday?")
    parser.add_argument("--list", action="store_true", help="List supported KPI questions.")
    parser.add_argument("--host", help="Target MySQL host. Defaults to TGT_HOST.")
    parser.add_argument("--port", type=int, default=int(os.getenv("DB_PORT", "3306")))
    parser.add_argument("--user", help="Database user. Defaults to DB_USER or admin.")
    parser.add_argument("--password", help="Database password. Defaults to DB_PASSWORD.")
    parser.add_argument("--database", help="Database name. Defaults to DB_NAME or demo.")
    parser.add_argument("--limit", type=int, default=20, help="Maximum rows to print.")
    parser.add_argument("--show-sql", action="store_true", help="Print matched SQL before running it.")
    parser.add_argument("--dry-run", action="store_true", help="Match the query but do not connect to MySQL.")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    queries = load_catalog()
    if args.list:
        list_queries(queries)
        return 0

    question = " ".join(args.question).strip()
    if not question:
        parser.error("Provide a question or use --list.")

    try:
        match = match_question(question, queries)
        sql = read_sql(match.query.sql_file)

        print(f"Question: {question}")
        print(f"Matched query: {match.query.query_id}")
        print(f"Description: {match.query.description}")
        print(f"SQL file: {match.query.sql_file.relative_to(REPO_ROOT)}")
        print(f"Matched terms: {', '.join(match.matched_terms)}")
        print()

        if args.show_sql or args.dry_run:
            print("SQL:")
            print(sql.strip())
            print()

        if args.dry_run:
            return 0

        columns, rows = run_query(sql, args)
        print("Result:")
        print_table(columns, rows)
        print()
        print("Summary:")
        print(summarize(match, len(rows)))
        return 0
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
