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
