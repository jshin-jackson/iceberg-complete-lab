#!/usr/bin/env python3
"""Lab 디렉터리·검증 SQL·run.sh 생성 (bootstrap)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LABS = ROOT / "labs"

DB = "iceberg_lab"

RUN_SH = """#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
COMMON="../common"
{run_body}
echo "run.sh 완료"
"""

VALIDATE_ALL = """#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
exec ../common/validate_triple.sh
"""

README_TEMPLATE = """# {title}

**트랙:** {track} | **학습:** {learn}

## 실행
```bash
cd {path}
./run.sh
./validate_all.sh
```

## 3엔진 검증
| 엔진 | 실습 | 검증 |
|------|------|------|
{engine_table}

선행: {prereq}
"""

LABS_SPEC = [
    {
        "dir": "lab-01-basic-table",
        "title": "Lab 01 — 기본 Iceberg 테이블",
        "track": "Core",
        "learn": "CREATE, INSERT, CRUD, 시스템 테이블, ofs warehouse",
        "prereq": "`.env` 설정, `kinit`",
        "table": "customers",
        "spark": [
            f"CREATE DATABASE IF NOT EXISTS {DB};",
            f"USE {DB};",
            "CREATE TABLE IF NOT EXISTS customers (",
            "  customer_id INT, name STRING, email STRING,",
            "  registration_date TIMESTAMP, country STRING,",
            "  age INT, gender STRING, vip_status BOOLEAN",
            ") USING iceberg;",
            "INSERT INTO customers VALUES",
            " (1, 'Alice', 'a@ex.com', timestamp '2021-01-01', 'KR', 30, 'F', true),",
            " (2, 'Bob', 'b@ex.com', timestamp '2021-06-01', 'US', 40, 'M', false);",
            "SELECT * FROM customers;",
            "SELECT * FROM customers.snapshots;",
        ],
        "hive": [
            f"USE {DB};",
            "INSERT INTO customers VALUES (3, 'Carol', 'c@ex.com', '2022-01-01', 'JP', 25, 'F', false);",
            "SELECT COUNT(*) AS cnt FROM customers;",
        ],
        "impala": [
            f"USE {DB};",
            "SELECT COUNT(*) AS cnt FROM customers;",
            "SELECT * FROM customers LIMIT 2;",
        ],
        "val_spark": f"USE {DB}; SELECT COUNT(*) AS cnt FROM customers HAVING COUNT(*) >= 2;",
        "val_hive": f"USE {DB}; SELECT COUNT(*) AS cnt FROM customers;",
        "val_impala": f"USE {DB}; SELECT COUNT(*) AS cnt FROM customers;",
        "engines": "Spark ● CREATE/INSERT | Hive ● INSERT | Impala ○ SELECT | validate 3엔진 COUNT",
    },
    {
        "dir": "lab-02-partitioning",
        "title": "Lab 02 — Hidden Partitioning",
        "track": "Core",
        "learn": "days(), bucket(), partition spec",
        "prereq": "Lab 01",
        "table": "orders_part",
        "spark": [
            f"USE {DB};",
            "CREATE TABLE IF NOT EXISTS orders_part (",
            "  order_id INT, customer_id INT, order_date TIMESTAMP, amount DOUBLE",
            ") USING iceberg",
            "PARTITIONED BY (days(order_date), bucket(16, customer_id));",
            "INSERT INTO orders_part VALUES",
            " (1, 1, timestamp '2024-01-15 10:00:00', 99.9),",
            " (2, 2, timestamp '2024-02-20 11:00:00', 50.0);",
            "EXPLAIN SELECT * FROM orders_part WHERE order_date >= '2024-02-01';",
        ],
        "hive": [
            f"USE {DB};",
            "SELECT COUNT(*) FROM orders_part WHERE order_date >= '2024-02-01';",
        ],
        "impala": [
            f"USE {DB};",
            "EXPLAIN SELECT * FROM orders_part WHERE order_date >= '2024-02-01';",
        ],
        "val_spark": f"USE {DB}; SELECT COUNT(*) AS cnt FROM orders_part;",
        "val_hive": f"USE {DB}; SELECT COUNT(*) AS cnt FROM orders_part;",
        "val_impala": f"USE {DB}; SELECT COUNT(*) AS cnt FROM orders_part;",
        "engines": "Spark ● DDL | Hive/Impala ○ EXPLAIN/SELECT",
    },
    {
        "dir": "lab-03-schema-evolution",
        "title": "Lab 03 — Schema Evolution",
        "track": "Core",
        "learn": "ADD/DROP/RENAME COLUMN",
        "prereq": "Lab 01 (customers)",
        "spark": [
            f"USE {DB};",
            "ALTER TABLE customers ADD COLUMNS (loyalty_tier STRING);",
            "UPDATE customers SET loyalty_tier = 'GOLD' WHERE customer_id = 1;",
            "ALTER TABLE customers RENAME COLUMN loyalty_tier TO tier;",
            "SELECT customer_id, tier FROM customers WHERE tier IS NOT NULL LIMIT 5;",
        ],
        "hive": [
            f"USE {DB};",
            "SELECT customer_id, tier FROM customers LIMIT 5;",
        ],
        "impala": [
            f"USE {DB};",
            "REFRESH customers;",
            "SELECT customer_id, tier FROM customers LIMIT 5;",
        ],
        "val_spark": f"USE {DB}; DESCRIBE customers;",
        "val_hive": f"USE {DB}; SELECT COUNT(*) FROM customers;",
        "val_impala": f"USE {DB}; SELECT COUNT(*) FROM customers;",
        "engines": "Spark ● ALTER | Hive/Impala ○ SELECT (+ REFRESH)",
    },
    {
        "dir": "lab-04-acid-transactions",
        "title": "Lab 04 — ACID / MERGE",
        "track": "Core",
        "learn": "MERGE INTO, snapshot 증가",
        "prereq": "Lab 01",
        "spark": [
            f"USE {DB};",
            "CREATE TABLE IF NOT EXISTS merge_demo (id INT, val STRING) USING iceberg;",
            "INSERT INTO merge_demo VALUES (1, 'old'), (2, 'keep');",
            "CREATE OR REPLACE TEMP VIEW upserts AS SELECT 1 AS id, 'new' AS val;",
            "MERGE INTO merge_demo t USING upserts s ON t.id = s.id",
            " WHEN MATCHED THEN UPDATE SET val = s.val",
            " WHEN NOT MATCHED THEN INSERT *;",
            "SELECT * FROM merge_demo ORDER BY id;",
            "SELECT COUNT(*) FROM merge_demo.snapshots;",
        ],
        "hive": [
            f"USE {DB};",
            "SELECT * FROM merge_demo ORDER BY id;",
        ],
        "impala": [
            f"USE {DB};",
            "SELECT COUNT(*) FROM merge_demo;",
        ],
        "val_spark": f"USE {DB}; SELECT COUNT(*) AS cnt FROM merge_demo HAVING COUNT(*) >= 2;",
        "val_hive": f"USE {DB}; SELECT COUNT(*) AS cnt FROM merge_demo;",
        "val_impala": f"USE {DB}; SELECT COUNT(*) AS cnt FROM merge_demo;",
        "engines": "Spark ● MERGE | Hive/Impala ○ SELECT",
    },
    {
        "dir": "lab-05-time-travel",
        "title": "Lab 05 — Time Travel & Branch",
        "track": "Core",
        "learn": "AS OF, FOR SYSTEM_TIME, tag",
        "prereq": "Lab 04 merge_demo",
        "spark": [
            f"USE {DB};",
            "INSERT INTO merge_demo VALUES (3, 'v3');",
            "SELECT * FROM merge_demo;",
            "SELECT snapshot_id, committed_at FROM merge_demo.snapshots ORDER BY committed_at DESC LIMIT 3;",
            "CREATE TAG IF NOT EXISTS tag_lab05 ON TABLE merge_demo;",
        ],
        "hive": [
            f"USE {DB};",
            "SELECT COUNT(*) FROM merge_demo;",
        ],
        "impala": [
            f"USE {DB};",
            "SELECT COUNT(*) FROM merge_demo;",
        ],
        "val_spark": f"USE {DB}; SELECT COUNT(*) AS cnt FROM merge_demo;",
        "val_hive": f"USE {DB}; SELECT COUNT(*) AS cnt FROM merge_demo;",
        "val_impala": f"USE {DB}; SELECT COUNT(*) AS cnt FROM merge_demo;",
        "engines": "Spark ● tag/snapshots | Hive ○ FOR SYSTEM_TIME | Impala ○ COUNT",
    },
    {
        "dir": "lab-06-merge-reads-writes",
        "title": "Lab 06 — MoR vs CoW",
        "track": "Core",
        "learn": "write.delete.mode, UPDATE",
        "prereq": "Lab 01",
        "spark": [
            f"USE {DB};",
            "CREATE TABLE IF NOT EXISTS mor_demo (id INT, val STRING) USING iceberg",
            "TBLPROPERTIES ('write.delete.mode'='merge-on-read', 'write.update.mode'='merge-on-read');",
            "INSERT INTO mor_demo VALUES (1, 'a'), (2, 'b');",
            "UPDATE mor_demo SET val = 'updated' WHERE id = 1;",
            "SELECT * FROM mor_demo ORDER BY id;",
        ],
        "hive": [
            f"USE {DB};",
            "SELECT * FROM mor_demo ORDER BY id;",
        ],
        "impala": [
            f"USE {DB};",
            "UPDATE mor_demo SET val = 'impala' WHERE id = 2;",
            "SELECT * FROM mor_demo ORDER BY id;",
        ],
        "val_spark": f"USE {DB}; SELECT COUNT(*) AS cnt FROM mor_demo;",
        "val_hive": f"USE {DB}; SELECT COUNT(*) AS cnt FROM mor_demo;",
        "val_impala": f"USE {DB}; SELECT COUNT(*) AS cnt FROM mor_demo;",
        "engines": "Spark ● properties/UPDATE | Impala ● UPDATE (MoR)",
    },
    {
        "dir": "lab-07-compaction",
        "title": "Lab 07 — Compaction",
        "track": "Core",
        "learn": "rewrite_data_files",
        "prereq": "Lab 06 mor_demo",
        "spark": [
            f"USE {DB};",
            "CALL hive_prod.system.rewrite_data_files(table => 'iceberg_lab.mor_demo');",
            "SELECT COUNT(*) FROM mor_demo;",
        ],
        "hive": [f"USE {DB};", "SELECT COUNT(*) FROM mor_demo;"],
        "impala": [f"USE {DB};", "SELECT COUNT(*) FROM mor_demo;"],
        "val_spark": f"USE {DB}; SELECT COUNT(*) AS cnt FROM mor_demo;",
        "val_hive": f"USE {DB}; SELECT COUNT(*) AS cnt FROM mor_demo;",
        "val_impala": f"USE {DB}; SELECT COUNT(*) AS cnt FROM mor_demo;",
        "engines": "Spark ● CALL | Hive/Impala ○ 검증",
    },
    {
        "dir": "lab-08-metadata-operations",
        "title": "Lab 08 — Metadata Ops",
        "track": "Core",
        "learn": "expire_snapshots",
        "prereq": "Lab 04",
        "spark": [
            f"USE {DB};",
            "CALL hive_prod.system.expire_snapshots(table => 'iceberg_lab.merge_demo', older_than => TIMESTAMP '2099-01-01 00:00:00', retain_last => 1);",
            "SELECT COUNT(*) FROM merge_demo.snapshots;",
        ],
        "hive": [f"USE {DB};", "SELECT COUNT(*) FROM merge_demo;"],
        "impala": [f"USE {DB};", "SELECT COUNT(*) FROM merge_demo;"],
        "val_spark": f"USE {DB}; SELECT COUNT(*) AS cnt FROM merge_demo;",
        "val_hive": f"USE {DB}; SELECT COUNT(*) AS cnt FROM merge_demo;",
        "val_impala": f"USE {DB}; SELECT COUNT(*) AS cnt FROM merge_demo;",
        "engines": "Spark ● expire | Hive/Impala ○ 검증",
    },
    {
        "dir": "lab-09-multi-engine",
        "title": "Lab 09 — Multi-Engine",
        "track": "Core",
        "learn": "동일 HMS 테이블 3엔진",
        "prereq": "Lab 01",
        "spark": [f"USE {DB};", "SELECT 'spark' AS engine, COUNT(*) AS cnt FROM customers;"],
        "hive": [f"USE {DB};", "SELECT 'hive' AS engine, COUNT(*) AS cnt FROM customers;"],
        "impala": [f"USE {DB};", "SELECT 'impala' AS engine, COUNT(*) AS cnt FROM customers;"],
        "val_spark": f"USE {DB}; SELECT COUNT(*) AS cnt FROM customers;",
        "val_hive": f"USE {DB}; SELECT COUNT(*) AS cnt FROM customers;",
        "val_impala": f"USE {DB}; SELECT COUNT(*) AS cnt FROM customers;",
        "engines": "3엔진 각 SELECT + validate",
    },
    {
        "dir": "lab-10-ozone-integration",
        "title": "Lab 10 — Ozone (Appendix)",
        "track": "Appendix",
        "learn": "ofs warehouse 경로",
        "prereq": "Lab 01",
        "spark": [f"USE {DB};", "DESCRIBE EXTENDED customers;"],
        "hive": [f"USE {DB};", "DESCRIBE customers;"],
        "impala": [f"USE {DB};", "DESCRIBE customers;"],
        "val_spark": f"USE {DB}; SELECT COUNT(*) AS cnt FROM customers;",
        "val_hive": f"USE {DB}; SELECT COUNT(*) AS cnt FROM customers;",
        "val_impala": f"USE {DB}; SELECT COUNT(*) AS cnt FROM customers;",
        "engines": "3엔진 DESCRIBE + COUNT",
    },
    {
        "dir": "lab-11-security",
        "title": "Lab 11 — Kerberos (Appendix)",
        "track": "Appendix",
        "learn": "systest keytab 연결",
        "prereq": "Lab 01",
        "spark": [f"USE {DB};", "SELECT 1 AS ok;"],
        "hive": [f"USE {DB};", "SELECT 1 AS ok;"],
        "impala": [f"USE {DB};", "SELECT 1 AS ok;"],
        "val_spark": f"USE {DB}; SELECT 1 AS ok;",
        "val_hive": f"USE {DB}; SELECT 1 AS ok;",
        "val_impala": f"USE {DB}; SELECT 1 AS ok;",
        "engines": "3엔진 SELECT 1",
    },
    {
        "dir": "lab-12-lakehouse-optimizer",
        "title": "Lab 12 — Optimizer (Appendix)",
        "track": "Appendix",
        "learn": "CM Optimizer vs Lab 07",
        "prereq": "Lab 07",
        "spark": [f"USE {DB};", "SELECT COUNT(*) FROM mor_demo;"],
        "hive": [f"USE {DB};", "SELECT COUNT(*) FROM mor_demo;"],
        "impala": [f"USE {DB};", "SELECT COUNT(*) FROM mor_demo;"],
        "val_spark": f"USE {DB}; SELECT COUNT(*) AS cnt FROM mor_demo;",
        "val_hive": f"USE {DB}; SELECT COUNT(*) AS cnt FROM mor_demo;",
        "val_impala": f"USE {DB}; SELECT COUNT(*) AS cnt FROM mor_demo;",
        "engines": "Optimizer UI 관찰 + 3엔진 COUNT",
    },
    {
        "dir": "lab-13-data-sharing",
        "title": "Lab 13 — REST Catalog (Appendix)",
        "track": "Appendix",
        "learn": "HMS vs REST 개념",
        "prereq": "Lab 01",
        "spark": [f"USE {DB};", "SELECT COUNT(*) FROM customers;"],
        "hive": [f"USE {DB};", "SELECT COUNT(*) FROM customers;"],
        "impala": [f"USE {DB};", "SELECT COUNT(*) FROM customers;"],
        "val_spark": f"USE {DB}; SELECT COUNT(*) AS cnt FROM customers;",
        "val_hive": f"USE {DB}; SELECT COUNT(*) AS cnt FROM customers;",
        "val_impala": f"USE {DB}; SELECT COUNT(*) AS cnt FROM customers;",
        "engines": "HMS 테이블 3엔진 (REST는 README)",
    },
]


def write_sql(path: Path, lines: list[str]):
    path.parent.mkdir(parents=True, exist_ok=True)
    body = f"-- {path.name}\n" + "\n".join(lines) + "\n"
    path.write_text(body, encoding="utf-8")


def main():
    for spec in LABS_SPEC:
        lab = LABS / spec["dir"]
        lab.mkdir(parents=True, exist_ok=True)
        run_lines = [
            'bash "$COMMON/run_spark_sql.sh" sql/spark/01_lab.sql',
            'bash "$COMMON/run_hive_sql.sh" sql/hive/01_lab.sql',
            'bash "$COMMON/run_impala_sql.sh" sql/impala/01_lab.sql',
        ]
        (lab / "run.sh").write_text(
            RUN_SH.format(run_body="\n".join(run_lines)),
            encoding="utf-8",
        )
        (lab / "validate_all.sh").write_text(VALIDATE_ALL, encoding="utf-8")
        write_sql(lab / "sql/spark/01_lab.sql", spec["spark"])
        write_sql(lab / "sql/hive/01_lab.sql", spec["hive"])
        write_sql(lab / "sql/impala/01_lab.sql", spec["impala"])
        (lab / "validate_spark.sql").write_text(spec["val_spark"] + ";\n", encoding="utf-8")
        (lab / "validate_hive.sql").write_text(spec["val_hive"] + ";\n", encoding="utf-8")
        (lab / "validate_impala.sql").write_text(spec["val_impala"] + ";\n", encoding="utf-8")
        engine_row = spec.get("engines", "")
        (lab / "README.md").write_text(
            README_TEMPLATE.format(
                title=spec["title"],
                track=spec["track"],
                learn=spec["learn"],
                path=f"labs/{spec['dir']}",
                engine_table=f"| Spark/Hive/Impala | {engine_row} |",
                prereq=spec["prereq"],
            ),
            encoding="utf-8",
        )
        print("created", spec["dir"])


if __name__ == "__main__":
    main()
