#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Spark SQL 파일 실행 (spark-sql / SparkSQLCLIDriver 없을 때 fallback)."""
from __future__ import annotations

import re
import sys

from pyspark.sql import SparkSession


def _split_sql(text: str) -> list[str]:
    lines = []
    for ln in text.splitlines():
        if ln.strip().startswith("--"):
            continue
        lines.append(ln)
    blob = "\n".join(lines)
    parts = re.split(r";\s*", blob)
    out = []
    for p in parts:
        stmt = p.strip()
        if stmt:
            out.append(stmt)
    return out


def _bootstrap_catalog(spark: SparkSession) -> None:
    catalog = spark.conf.get("spark.sql.defaultCatalog", "hive_prod")
    db = spark.conf.get("spark.iceberg.lab.database", "iceberg_lab")
    spark.catalog.setCurrentCatalog(catalog)
    spark.sql(f"CREATE DATABASE IF NOT EXISTS `{db}`")
    spark.catalog.setCurrentDatabase(db)


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("usage: spark_sql_file_runner.py file.sql")
    path = sys.argv[1]
    spark = (
        SparkSession.builder.appName("iceberg-complete-lab")
        .enableHiveSupport()
        .getOrCreate()
    )
    try:
        _bootstrap_catalog(spark)
        text = open(path, encoding="utf-8").read()
        for stmt in _split_sql(text):
            upper = stmt.lstrip().upper()
            if upper.startswith("CREATE DATABASE") or upper.startswith("USE "):
                continue
            print(f"-- executing: {stmt[:80]}...", flush=True)
            spark.sql(stmt)
    finally:
        spark.stop()


if __name__ == "__main__":
    main()
