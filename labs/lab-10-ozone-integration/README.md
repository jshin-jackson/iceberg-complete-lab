# Lab 10 — Ozone 연동 (Appendix)

**트랙:** Appendix (CDP·스토리지)  
**난이도:** 입문 (경로 이해)

## 이 Lab에서 배우는 것

Iceberg **데이터 파일**과 **메타데이터 파일**은 “warehouse”라는 **루트 경로** 아래에 저장됩니다. 이 Lab 환경에서는 Cloudera **Ozone** 객체 스토리지를 **`ofs://`** 프로토콜로 사용합니다.

예: `.env`의 `WAREHOUSE_OFS=ofs://ozone1784520717/vol1/bucket1/warehouse`

### 초급자 체크리스트

1. **테이블 LOCATION / warehouse** — Iceberg가 실제 Parquet·메타 JSON을 쓰는 곳
2. **Ozone volume·bucket** — 조직에서 정한 네임스페이스 (`.env`의 `OZONE_*`)
3. **3엔진 모두** 같은 warehouse를 바라보도록 Spark/Hive/Impala 설정이 맞아야 Lab 01~09가 성공합니다

이 Lab은 “Iceberg 기능”보다 **저장소가 Ozone일 때 테이블이 어디에 있는지**를 **DESCRIBE·COUNT**로 확인합니다.

## 실행 방법

```bash
cd labs/lab-10-ozone-integration
./run.sh
./validate_all.sh
```

## 3엔진 검증

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark / Hive / Impala** | **DESCRIBE** (스키마·위치) + **COUNT** | 세 엔진 결과 일치 |

## 선행 Lab

**Lab 01** — `iceberg_lab` 등 기본 테이블이 Ozone warehouse에 이미 있어야 합니다.

## 다음 Lab

**Lab 11** — **Kerberos**로 Spark/Hive/Impala에 안전하게 접속하는지 확인합니다.

## 더 읽기

프로젝트 `docs/04-ozone-storage.md` — Ozone과 Iceberg warehouse 개념을 더 정리해 두었을 수 있습니다.
