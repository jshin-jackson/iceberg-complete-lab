#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Spark SQL 파일 실행 (spark-sql / SparkSQLCLIDriver 없을 때 fallback)."""
from __future__ import annotations

import re
import sys

from pyspark.sql import SparkSession


def _split_sql(text: str) -> list[str]:
    # Lab SQL: ';' 로 구문 분리 (문자열 리터럴 단순 케이스만)
    parts = re.split(r";\s*\n", text)
    out = []
    for p in parts:
        stmt = p.strip()
        if not stmt or stmt.startswith("--"):
            continue
        lines = [ln for ln in stmt.splitlines() if not ln.strip().startswith("--")]
        stmt = "\n".join(lines).strip()
        if stmt:
            out.append(stmt)
    return out


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("usage: spark_sql_file_runner.py file.sql")
    path = sys.argv[1]
    spark = SparkSession.builder.appName("iceberg-complete-lab").enableHiveSupport().getOrCreate()
    try:
        text = open(path, encoding="utf-8").read()
        for stmt in _split_sql(text):
            spark.sql(stmt)
    finally:
        spark.stop()


if __name__ == "__main__":
    main()
