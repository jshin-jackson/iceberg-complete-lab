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

## Spark 3 SQL (`spark3-sql`)

Lab Spark 실습은 [`labs/common/run_spark_sql.sh`](../labs/common/run_spark_sql.sh)가 **Iceberg catalog conf**와 함께 CLI를 호출합니다.

CDP **edge**에서는 `spark3-sql` 이 PATH에 없을 수 있습니다. **`run.sh` / `run_spark_sql.sh`는 다음을 자동 시도**합니다.

1. `.env`의 `SPARK_ENV_SCRIPT` 또는 `/etc/spark3/conf.cloudera.spark3_on_yarn/spark-env.sh` 등 **source**
2. `SPARK_SQL_CMD` → `spark3-sql` → `spark-sql` → `/opt/cloudera/parcels/SPARK3/bin/spark3-sql`

수동 확인:

```bash
source /etc/spark3/conf.cloudera.spark3_on_yarn/spark-env.sh   # 경로는 CM/parcel 버전마다 다를 수 있음
which spark3-sql
spark3-sql --version
```

| `.env` | 설명 |
|--------|------|
| `SPARK_MASTER` | 기본 `yarn` (Lab Iceberg 쓰기) |
| `SPARK_SQL_CMD` | CLI 전체 경로 (자동 탐색 실패 시) |
| `SPARK_ENV_SCRIPT` | `spark-env.sh` 위치 (자동 후보 외 지정) |

 `./scripts/validate.sh`의 Spark 줄에서 CLI 경로를 확인할 수 있습니다.

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

Lab의 Hive 검증은 [`labs/common/run_hive_sql.sh`](../labs/common/run_hive_sql.sh) → **beeline** `-f` 로 SQL 파일을 실행합니다.

CM **hiveserver2_load_balancer**:

`ccycloud-1.jshin.root.comops.site:10015`

(예전 문서의 **`10000`** 포트가 아니라, 이 환경에서는 **SSL/load balancer `10015`** 를 사용합니다.)

### 수동 접속 예

**Kerberos** (Beeline help 형식 — `principal` 은 HS2 **호스트 FQDN**과 맞춤):

```bash
kinit -kt /cdep/keytabs/systest.keytab systest
beeline -u "jdbc:hive2://ccycloud-1.jshin.root.comops.site:10015/default;principal=hive/ccycloud-1.jshin.root.comops.site@QE-INFRA-AD.CLOUDERA.COM"
```

**SSL** (truststore 경로·비밀번호는 CM/agent 쪽 설정 확인):

```bash
beeline -u "jdbc:hive2://ccycloud-1.jshin.root.comops.site:10015/default;ssl=true;sslTrustStore=/var/lib/cloudera-scm-agent/agent-cert/cm-auto-global_truststore.jks;trustStorePassword=changeit;principal=hive/ccycloud-1.jshin.root.comops.site@QE-INFRA-AD.CLOUDERA.COM"
```

Kerberos + SSL을 **한 URL**에 넣는 것이 CDP edge에서 흔한 패턴입니다. Lab `.env`의 `HIVE_SERVER2_JDBC` 또는 `HIVESERVER2_*` / `HIVE_SSL_*` 가 [`run_hive_sql.sh`](../labs/common/run_hive_sql.sh)에서 조립됩니다.

| 항목 | `.env` / 값 |
|------|-------------|
| Load balancer | `HIVESERVER2_LOAD_BALANCER=ccycloud-1.jshin.root.comops.site:10015` |
| HMS URIs | `HMS_URI` (2대 thrift) |
| HS2 principal | `HIVE_SERVER2_PRINCIPAL=hive/<hs2-host-fqdn>@REALM` |
| SSL | `HIVE_SERVER2_SSL=true`, `HIVE_SSL_TRUSTSTORE`, `HIVE_SSL_TRUSTSTORE_PASSWORD=changeit` (CM `cm-auto-global_truststore.jks`) |
| 전체 JDBC | `HIVE_SERVER2_JDBC` (있으면 우선) |

**Principal 참고:** 문서 예시 `hive/localhost@mydomain.com` 과 같이 **`hive/_HOST@REALM` 이 아니라 접속 URL 호스트와 같은 FQDN** 을 쓰는 경우가 많습니다. 연결 오류 시 CM HiveServer2 **Principal** 필드와 Beeline URL host 가 일치하는지 확인하세요.

Lab SQL에는 `USE iceberg_lab;` 가 포함되어 있어 JDBC database 는 `default` 로 두어도 됩니다 (`HIVE_SERVER2_JDBC_DATABASE=default`).

