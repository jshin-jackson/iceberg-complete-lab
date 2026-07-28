# Lab 11 — Kerberos 보안 (Appendix)

**트랙:** Appendix (CDP·보안)  
**난이도:** 입문 (연결 확인)

## 이 Lab에서 배우는 것

많은 Cloudera 클러스터는 **Kerberos**로 서비스·사용자를 인증합니다. SQL을 실행하기 전에:

1. **keytab** 파일 (예: `systest.keytab`)로 **principal**에 로그인 (`kinit`)
2. Spark YARN·HiveServer2 JDBC·Impala 연결 시 **같은 principal** / delegation token 규칙 준수

이 Lab은 Iceberg 문법보다 **“인증이 맞을 때 3엔진이 살아 있는지”** 를 가장 단순한 쿼리로 확인합니다.

### .env와 관련된 값 (예시)

| 변수 | 의미 |
|------|------|
| `KERBEROS_PRINCIPAL` | 사용자 principal (예: `systest@...`) |
| `KERBEROS_KEYTAB` | keytab 파일 경로 |
| `SPARK_YARN_*` | Spark on YARN 제출 시 사용하는 principal/keytab |
| `IMPALA_DAEMON` | Impala coordinator **`host:25003`** (SSL; 21000 아님) |
| `IMPALA_SSL` / `IMPALA_CA_CERT` | `--ssl`, CM `cm-auto-global_cacerts.pem` |
| `IMPALA_PROTOCOL` | Lab 기본 `beeswax` ([`docs/03-cloudera-integration.md`](../../docs/03-cloudera-integration.md)) |

수동 접속 예:

```bash
kinit -kt /cdep/keytabs/systest.keytab systest
impala-shell -i ccycloud-5.jshin.root.comops.site:25003 --protocol=beeswax -d default -k \
  --ssl --ca_cert=/var/lib/cloudera-scm-agent/agent-cert/cm-auto-global_cacerts.pem
```

Lab SQL은 `env.sh` + [`run_impala_sql.sh`](../../common/run_impala_sql.sh)가 위와 같은 `.env`(`IMPALA_*`) 옵션으로 실행합니다.

## 실행 방법

```bash
cd labs/lab-11-security
./run.sh
./validate_all.sh
```

## 3엔진 검증

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark / Hive / Impala** | **`SELECT 1`** (또는 동등한 연결 테스트) | 세 엔진 모두 성공 |

실패 시: keytab 만료, principal 오타, HS2/Impala **SPNEGO/principal** 불일치, 방화벽을 순서대로 확인하세요. `docs/troubleshooting.md` 참고.

**Kerberos는 통과하는데 `ofs://` / Iceberg 쓰기만 거부**되면 인증 문제가 아니라 **권한**일 가능성이 큽니다. Ranger **OZONE (`cm_ozone`)** 정책은 Lab 01 전에 [`docs/04-ozone-storage.md`](../../docs/04-ozone-storage.md) **§3**을 따르세요.

## 선행 Lab

**Lab 01** — `.env`와 클러스터 접속 흐름을 이미 맞춰 두었다고 가정합니다. Kerberos 문제를 **먼저** 풀고 Lab 01~09를 진행해도 됩니다.

## 다음 Lab

**Lab 12** — Cloudera Manager **Lakehouse Optimizer**와 Lab 07의 **수동 compaction** 차이를 관찰합니다.
