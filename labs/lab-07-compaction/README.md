# Lab 07 — Compaction (파일 정리)

**트랙:** Core  
**난이도:** 중급

## 이 Lab에서 배우는 것

데이터를 자주 INSERT·UPDATE하면 **작은 Parquet 파일**이 많아집니다. 파일 하나마다 메타·I/O 비용이 있어 **읽기가 느려집니다**.

**Compaction**은 여러 작은 데이터 파일을 **더 적은 큰 파일**로 다시 쓰는 유지보수 작업입니다.

Iceberg Spark에서는 stored procedure 형태로 자주 호출합니다:

- **`rewrite_data_files`** — 데이터 파일 재작성 (이 Lab의 핵심)

compaction 후에도 **논리적 데이터(행)** 는 같고, **물리적 파일 layout**만 바뀝니다.

## 실행 방법

```bash
cd labs/lab-07-compaction
./run.sh
./validate_all.sh
```

`run.sh` 안에서 Spark **`CALL catalog.system.rewrite_data_files(...)`** 류 SQL을 실행합니다. catalog 이름은 `.env`의 `ICEBERG_CATALOG`와 맞춥니다.

## 3엔진 검증

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark** | ● **CALL** 로 compaction 실행 | — |
| **Hive / Impala** | ○ compaction **전·후** COUNT 등으로 **데이터 동일성** 확인 | — |

Compaction **실행**은 Spark, **검증 읽기**는 3엔진으로 하는 패턴입니다.

## 선행 Lab

**Lab 06** — **`mor_demo`** 등 UPDATE/MoR로 파일이 쪼개진 상태를 만든 뒤 compaction 효과를 보기 좋습니다.

## 다음 Lab

**Lab 08** — 오래된 **스냅샷**을 지워 저장소를 줄이는 **`expire_snapshots`** 를 배웁니다.
