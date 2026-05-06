from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd
import streamlit as st

from db import connection_config, query_df, read_sql


REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from ai.ask_dashboard import load_catalog, match_question, summarize  # noqa: E402


st.set_page_config(
    page_title="Near Real-Time Business Metrics",
    page_icon=":bar_chart:",
    layout="wide",
)


def money(value: float | int | None) -> str:
    if value is None or pd.isna(value):
        return "-"
    return f"INR {value:,.0f}"


def pct(value: float | int | None) -> str:
    if value is None or pd.isna(value):
        return "-"
    return f"{value:.2f}%"


@st.cache_data(ttl=10)
def run_sql(sql: str, host: str, user: str, password: str, database: str, port: int) -> pd.DataFrame:
    config = connection_config(host=host, user=user, password=password, database=database, port=port)
    return query_df(sql, config)


def run_query_file(path: str, config: dict[str, str | int]) -> pd.DataFrame:
    return run_sql(
        read_sql(path),
        str(config["host"]),
        str(config["user"]),
        str(config["password"]),
        str(config["database"]),
        int(config["port"]),
    )


def main() -> None:
    st.title("Near Real-Time Business Metrics")
    st.caption("AWS DMS CDC -> RDS MySQL target -> KPI queries")

    with st.sidebar:
        st.header("Connection")
        default_config = connection_config()
        host = st.text_input("Target host", value=str(default_config["host"]))
        database = st.text_input("Database", value=str(default_config["database"]))
        user = st.text_input("User", value=str(default_config["user"]))
        password = st.text_input("Password", value=str(default_config["password"]), type="password")
        port = st.number_input("Port", value=int(default_config["port"]), step=1)
        refresh = st.button("Refresh")

        st.divider()
        st.caption("Values are read from local `.env` when present. Do not commit `.env`.")

    if refresh:
        st.cache_data.clear()

    if not host or not password:
        st.warning("Set TGT_HOST and DB_PASSWORD in `.env`, or enter them in the sidebar.")
        return

    config = {
        "host": host,
        "database": database,
        "user": user,
        "password": password,
        "port": int(port),
    }

    try:
        freshness = run_query_file("analytics/queries/freshness.sql", config)
        dau = run_query_file("analytics/queries/dau.sql", config)
        conversion = run_query_file("analytics/queries/conversion_rate.sql", config)
        payments = run_query_file("analytics/queries/payment_success_rate.sql", config)
        failures = run_query_file("analytics/queries/failed_payments_by_reason.sql", config)
        funnel = run_query_file("analytics/queries/funnel_daily.sql", config)
        geo = run_query_file("analytics/queries/geo_segmentation.sql", config)
        devices = run_query_file("analytics/queries/device_segmentation.sql", config)
        reconciliation = run_query_file("analytics/queries/reconciliation_daily.sql", config)
        recent = run_sql(
            """
            SELECT transaction_id, customer_id, merchant_id, amount, transaction_status, channel, event_ts
            FROM transactions
            ORDER BY transaction_id DESC
            LIMIT 25
            """,
            host,
            user,
            password,
            database,
            int(port),
        )
    except Exception as exc:
        st.error(f"Could not load dashboard data: {exc}")
        return

    latest_dau = dau.iloc[-1]["daily_active_users"] if not dau.empty else None
    latest_conversion = conversion.iloc[-1]["conversion_rate_pct"] if not conversion.empty else None
    latest_success = payments.iloc[-1]["success_rate_pct"] if not payments.empty else None
    latest_gtv = reconciliation.iloc[-1]["gross_transaction_value"] if not reconciliation.empty else None
    freshness_sec = freshness["freshness_sec"].min() if not freshness.empty else None

    c1, c2, c3, c4, c5 = st.columns(5)
    c1.metric("DAU", f"{latest_dau:,.0f}" if latest_dau is not None else "-")
    c2.metric("Conversion", pct(latest_conversion))
    c3.metric("Payment Success", pct(latest_success))
    c4.metric("GTV", money(latest_gtv))
    c5.metric("Freshness", f"{freshness_sec:.0f}s" if freshness_sec is not None else "-")

    tab_overview, tab_funnel, tab_segments, tab_ask, tab_data = st.tabs(
        ["Overview", "Funnel", "Segments", "Ask", "Data"]
    )

    with tab_overview:
        left, right = st.columns(2)
        with left:
            st.subheader("Daily Active Users")
            st.line_chart(dau, x="metric_date", y="daily_active_users")
        with right:
            st.subheader("Payment Success Rate")
            st.line_chart(payments, x="metric_date", y="success_rate_pct")

        left, right = st.columns(2)
        with left:
            st.subheader("Conversion Rate")
            st.line_chart(conversion, x="metric_date", y="conversion_rate_pct")
        with right:
            st.subheader("Failed Payments by Reason")
            if not failures.empty:
                failure_chart = failures.groupby("failure_reason", as_index=False)["failed_payments"].sum()
                st.bar_chart(failure_chart, x="failure_reason", y="failed_payments")
            else:
                st.info("No failed payments found.")

        st.subheader("Recent Transactions")
        st.dataframe(recent, use_container_width=True, hide_index=True)

    with tab_funnel:
        st.subheader("Daily Funnel")
        if not funnel.empty:
            latest = funnel.iloc[-1]
            funnel_df = pd.DataFrame(
                {
                    "step": [
                        "login",
                        "view_merchant",
                        "payment_initiated",
                        "payment_success",
                        "purchase_completed",
                    ],
                    "sessions": [
                        latest["login_sessions"],
                        latest["merchant_view_sessions"],
                        latest["payment_started_sessions"],
                        latest["payment_success_sessions"],
                        latest["purchase_sessions"],
                    ],
                }
            )
            st.bar_chart(funnel_df, x="step", y="sessions")
            st.dataframe(funnel, use_container_width=True, hide_index=True)

    with tab_segments:
        left, right = st.columns(2)
        with left:
            st.subheader("Active Users by City")
            if not geo.empty:
                city_df = geo.groupby("city", as_index=False)["active_users"].sum()
                st.bar_chart(city_df, x="city", y="active_users")
        with right:
            st.subheader("Payment Success by City")
            if not geo.empty:
                st.dataframe(
                    geo[["city", "payment_attempts", "successful_payments", "payment_success_rate_pct"]]
                    .sort_values("payment_success_rate_pct")
                    .reset_index(drop=True),
                    use_container_width=True,
                )

        st.subheader("Device and OS Segments")
        st.dataframe(devices, use_container_width=True, hide_index=True)

    with tab_ask:
        st.subheader("Ask Your Dashboard")
        st.caption("Questions are matched to approved SQL files in `ai/query_catalog.yaml`.")
        question = st.text_input("Question", value="How fresh is the dashboard?")
        show_sql = st.checkbox("Show matched SQL", value=False)
        if st.button("Run question"):
            try:
                catalog = load_catalog()
                match = match_question(question, catalog)
                sql = match.query.sql_file.read_text(encoding="utf-8")
                result = run_sql(sql, host, user, password, database, int(port))
                st.success(f"Matched: {match.query.query_id}")
                st.caption(match.query.description)
                st.dataframe(result, use_container_width=True, hide_index=True)
                st.info(summarize(match, len(result)))
                if show_sql:
                    st.code(sql, language="sql")
            except Exception as exc:
                st.error(str(exc))

        st.markdown("Try:")
        st.code(
            "\n".join(
                [
                    "What was DAU yesterday?",
                    "Show failed payments by reason.",
                    "Which city had the lowest payment success rate?",
                    "Compare mobile and web conversion.",
                    "Where are users dropping off?",
                ]
            )
        )

    with tab_data:
        st.subheader("Freshness")
        st.dataframe(freshness, use_container_width=True, hide_index=True)
        st.subheader("Reconciliation")
        st.dataframe(reconciliation, use_container_width=True, hide_index=True)
        st.subheader("Raw KPI Tables")
        st.dataframe(dau, use_container_width=True, hide_index=True)
        st.dataframe(conversion, use_container_width=True, hide_index=True)
        st.dataframe(payments, use_container_width=True, hide_index=True)


if __name__ == "__main__":
    main()
