# Cloudera 7.3.2 연동

- Iceberg **1.5.2**, Spark **3.5.4**, Impala **4.5.0**
- Catalog: `SparkCatalog` + `type=hive` → HMS
- Warehouse: `ofs://ozone1784520717/...` ([`config/spark-defaults.conf`](../config/spark-defaults.conf))  
  **Volume/bucket이 없으면** 먼저 [`04-ozone-storage.md`](04-ozone-storage.md) · `./scripts/setup_ozone_storage.sh`
- Lakehouse Optimizer: Lab 12 (CM UI)

문서: [Using Iceberg with Spark 7.3.2](https://docs.cloudera.com/runtime/7.3.2/spark-iceberg/topics/spark-using-iceberg.html)
