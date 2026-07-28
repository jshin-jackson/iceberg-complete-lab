# Cloudera 7.3.2 연동

- Iceberg **1.5.2**, Spark **3.5.4**, Impala **4.5.0** (예: `impalad 4.5.0.7.3.2.0-957`)
- Catalog: `SparkCatalog` + `type=hive` → HMS
- Warehouse: `ofs://ozone1784520717/...` ([`config/spark-defaults.conf`](../config/spark-defaults.conf))  
  **Volume/bucket이 없으면** 먼저 [`04-ozone-storage.md`](04-ozone-storage.md) · `./scripts/setup_ozone_storage.sh`
- Lakehouse Optimizer: Lab 12 (CM UI)

문서: [Using Iceberg with Spark 7.3.2](https://docs.cloudera.com/runtime/7.3.2/spark-iceberg/topics/spark-using-iceberg.html)

---

## Impala shell (Kerberos + SSL)

CDP edge에서 Lab과 동일한 방식으로 접속할 때 예시는 아래와 같습니다. **포트 `21000`이 아니라 coordinator SSL 포트(여기서는 `25003`)** 를 씁니다.

```bash
kinit -kt /cdep/keytabs/systest.keytab systest
impala-shell -i ccycloud-5.jshin.root.comops.site:25003 \
  --protocol=beeswax \
  -d default \
  -k \
  --ssl \
  --ca_cert=/var/lib/cloudera-scm-agent/agent-cert/cm-auto-global_cacerts.pem
```

| 항목 | 값 | 비고 |
|------|-----|------|
| Coordinator | `ccycloud-5.jshin.root.comops.site:25003` | `.env` → `IMPALA_DAEMON` |
| Kerberos | `-k` | service name `impala` (shell이 자동 사용) |
| SSL | `--ssl` + `--ca_cert=...` | CM agent CA (`cm-auto-global_cacerts.pem`) |
| Protocol | `--protocol=beeswax` | Impala 4.5에서 **deprecated** 경고가 나올 수 있음; Lab 스크립트 기본값 |
| 시작 DB | `-d default` | Lab SQL에 `USE iceberg_lab;` 포함 |

Lab SQL 실행은 [`labs/common/run_impala_sql.sh`](../labs/common/run_impala_sql.sh)가 `.env`의 `IMPALA_*` 변수를 읽어 **위 옵션과 동일하게** `impala-shell -f` 를 호출합니다.

`.env` 예시는 [`.env.example`](../.env.example) 를 복사해 coordinator 호스트만 본인 클러스터에 맞게 바꿉니다.

### Impala 관련 `.env` 변수

| 변수 | 설명 |
|------|------|
| `IMPALA_DAEMON` | `host:port` (SSL listener) |
| `IMPALA_PROTOCOL` | 기본 `beeswax` |
| `IMPALA_SSL` | `true` / `false` |
| `IMPALA_CA_CERT` | SSL CA PEM 경로 |
| `IMPALA_DEFAULT_DATABASE` | `impala-shell -d` (Lab DB는 SQL에서 `USE ${LAB_DATABASE}`) |

SSL 없는 환경만 `IMPALA_SSL=false` 로 두면 `--ssl` / `--ca_cert` 를 붙이지 않습니다.

---

## Spark 3 SQL (CDH parcel: `spark-class` fallback)

Lab Spark 실습은 [`labs/common/run_spark_sql.sh`](../labs/common/run_spark_sql.sh)가 **Iceberg catalog conf**와 함께 SQL 파일을 제출합니다.

edge `/opt/cloudera/parcels/CDH/lib/spark3/bin` 에 **`spark-sql` / `spark3-sql` 이 없고** `spark-class`, `load-spark-env.sh`, `spark-submit` 만 있는 구성이 있습니다.

**`run_spark_sql.sh` 자동 동작:**

1. `load-spark-env.sh` (CDH) · `/etc/spark3/conf*/spark-env.sh` source
2. `spark3-sql` / `spark-sql` 이 있으면 해당 CLI
3. 없으면 **`spark-submit`** + driver classpath → `SparkSQLCLIDriver`, 실패 시 **`spark_sql_file_runner.py`** (PySpark)
4. **`SPARK_CONF_DIR`** = `/etc/spark3/conf.cloudera.SPARK3_ON_YARN*` 자동 설정

진단:

```bash
./scripts/detect_spark_client.sh
ls -l /opt/cloudera/parcels/CDH/lib/spark3/bin
```

`.env`: 없는 경로의 **`SPARK_SQL_CMD=.../spark-sql` 을 제거**하세요 (자동 fallback 사용).

| `.env` | 설명 |
|--------|------|
| `SPARK_MASTER` | 기본 `yarn` |
| `SPARK_SQL_CMD` | (선택) 실제 존재하는 CLI만 |
| `SPARK_SQL_MAIN_CLASS` | fallback (기본 `SparkSQLCLIDriver`) |

 `./scripts/validate.sh` Spark 줄에서 runner 확인.

---

## HDFS HA (Standby NameNode WARN)

Spark on YARN 은 Iceberg 데이터가 **Ozone(`ofs://`)** 에 있어도, 제출 시 **HDFS staging** (`copyFileToRemote` 등)을 씁니다. edge 에 CM **HDFS HA** 설정이 없으면 특정 호스트(`ccycloud-2:8020`)로 붙었다가 다음 WARN 이 날 수 있습니다.

`Operation category READ is not supported in state standby`

**대응 (Lab 스크립트):** [`run_spark_sql.sh`](../labs/common/run_spark_sql.sh) 가 [`hadoop_env.sh`](../labs/common/hadoop_env.sh) 로 **`HADOOP_CONF_DIR=/etc/hadoop/conf`** 를 export 합니다. Iceberg warehouse 는 계속 `.env` 의 `WAREHOUSE_OFS`(Ozone) 입니다.

edge `.env`:

```bash
HADOOP_CONF_DIR=/etc/hadoop/conf
YARN_CONF_DIR=/etc/hadoop/conf
# nameservice URI (단일 NN host 가 아님)
HDFS_DEFAULT_FS=hdfs://YOUR_NAMESERVICE
```

nameservice 확인:

```bash
hdfs getconf -confKey fs.defaultFS
# 예: hdfs://jshincluster  (ccycloud-2:8020 같은 host:port 가 아님)
```

선택 — YARN staging 경로를 nameservice 로 고정:

```bash
SPARK_YARN_STAGING_DIR=hdfs://YOUR_NAMESERVICE/user/spark/.sparkStaging
```

**참고:** HA 설정이 맞으면 클라이언트가 **Active NN** 으로 failover 하며, WARN 1~2줄 후 성공하는 경우도 있습니다. job 이 실패하면 `HDFS_DEFAULT_FS` 가 **standby 호스트**를 가리키지 않는지 CM **HDFS → Instances** Active NameNode 와 대조하세요.

---

## Hive Metastore (HMS)

Iceberg 테이블 메타는 **Hive Metastore** Thrift API(`9083`)에 저장됩니다. 이 클러스터는 **HMS 2대**가 동시에 기동 중입니다.

| Host | 역할 |
|------|------|
| `ccycloud-1.jshin.root.comops.site:9083` | HMS |
| `ccycloud-3.jshin.root.comops.site:9083` | HMS |

클라이언트(Spark, Hive, PyIceberg)는 보통 **두 URI를 쉼표로** 지정합니다 (`.env` → `HMS_URI`):

```properties
thrift://ccycloud-1.jshin.root.comops.site:9083,thrift://ccycloud-3.jshin.root.comops.site:9083
```

[`config/spark-defaults.conf`](../config/spark-defaults.conf)의 `spark.hadoop.hive.metastore.uris` 도 동일하게 맞춥니다.

---

## Beeline / HiveServer2 (Kerberos + SSL)

Lab Hive: [`run_hive_sql.sh`](../labs/common/run_hive_sql.sh). 대화형: [`scripts/beeline.sh`](../scripts/beeline.sh) (`.env` JDBC).

**동작 확인된** CM ZK JDBC — `2181` quorum, DB **`default`**, `principal=hive/ccycloud-1.jshin.root.comops.site@REALM`, `retries=5`, `keyStoreType` / `zookeeper*StoreType=jks`. ZK 가 HS2 `:10000` 등 실제 엔드포인트를 선택합니다. **`auth=KERBEROS` 는 URL에 넣지 않습니다** (CM/beeline 대화형과 동일).

```bash
kinit -kt /cdep/keytabs/systest.keytab systest
cd ~/iceberg-complete-lab
./scripts/beeline.sh
# ./scripts/test_beeline_connect.sh
```

`.env` [`HIVE_SERVER2_JDBC`](../.env.example) 또는 [`hive_jdbc.sh`](../labs/common/hive_jdbc.sh) 조립 URL 예:

```text
jdbc:hive2://ccycloud-1...:2181,ccycloud-2...:2181,ccycloud-3...:2181/default;keyStoreType=jks;principal=hive/ccycloud-1.jshin.root.comops.site@QE-INFRA-AD.CLOUDERA.COM;retries=5;serviceDiscoveryMode=zooKeeper;ssl=true;sslTrustStore=/var/lib/cloudera-scm-agent/agent-cert/cm-auto-global_truststore.jks;trustStorePassword=***;trustStoreType=jks;zooKeeperNamespace=hiveserver2;zookeeperKeyStoreType=jks;zookeeperTrustStoreType=jks
```

예전 **HAProxy `:10015`** JDBC 줄은 `.env` 에서 제거. LB 는 `HIVE_SERVER2_CONNECT=lb` (부록).

| `.env` | 값 |
|--------|-----|
| `HIVE_SERVER2_JDBC` | 위 한 줄 (우선) |
| `HIVE_SERVER2_PRINCIPAL` | `hive/ccycloud-1.jshin.root.comops.site@...` |
| `HIVE_SERVER2_JDBC_DATABASE` | `default` |
| `HIVE_SERVER2_JDBC_RETRIES` | `5` |

Lab SQL 은 `USE iceberg_lab;` 포함 — JDBC DB 는 `default`.

