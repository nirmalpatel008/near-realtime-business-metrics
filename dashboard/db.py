"""Database helpers for the Streamlit dashboard."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import mysql.connector
import pandas as pd


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


def connection_config(
    host: str | None = None,
    user: str | None = None,
    password: str | None = None,
    database: str | None = None,
    port: int | None = None,
) -> dict[str, Any]:
    load_dotenv()
    return {
        "host": host or os.getenv("TGT_HOST", ""),
        "user": user or os.getenv("DB_USER", "admin"),
        "password": password or os.getenv("DB_PASSWORD", ""),
        "database": database or os.getenv("DB_NAME", "demo"),
        "port": port or int(os.getenv("DB_PORT", "3306")),
    }


def query_df(sql: str, config: dict[str, Any]) -> pd.DataFrame:
    conn = mysql.connector.connect(**config)
    try:
        return pd.read_sql(sql, conn)
    finally:
        conn.close()


def read_sql(relative_path: str) -> str:
    return (REPO_ROOT / relative_path).read_text(encoding="utf-8")
