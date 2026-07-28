# iceberg-complete-lab

**Apache Iceberg**를 손으로 익히는 실습 모음입니다.  
Cloudera Data Platform(CDP) **7.3.2**, Iceberg **1.5.2**, Spark **3.5.4** 환경을 기준으로 작성되어 있습니다.

## Iceberg가 뭔가요?

일반적인 데이터 레이크(Parquet 파일만 쌓아 두는 방식)와 달리, Iceberg는 **표 형태의 데이터를 안전하게 읽고 쓰기 위한 “테이블 형식”**입니다.

- **스냅샷**: 데이터를 바꿀 때마다 “그 시점의 상태”를 기록해 두어, 나중에 과거 버전을 조회할 수 있습니다.
- **메타데이터**: 어떤 파일에 어떤 데이터가 있는지 Iceberg가 관리합니다. Hive Metastore(HMS)와 함께 쓰는 경우가 많습니다.
- **여러 엔진**: Spark, Hive, Impala 등이 **같은 Iceberg 테이블**을 동시에 사용할 수 있습니다.

이 저장소는 위 개념을 **Lab 01~13** 순서로 SQL 실습과 검증 스크립트로 연습할 수 있게 구성되어 있습니다.

## 이 Lab이 사용하는 환경 (참고)

| 항목 | 예시 값 |
|------|---------|
| Kerberos 계정 | `systest@QE-INFRA-AD.CLOUDERA.COM` |
| Ozone 저장소(warehouse) | `ofs://ozone1784520717/...` |

실제 호스트 이름·경로는 클러스터마다 다릅니다. 아래 **시작하기**에서 `.env`로 맞춰 주세요.

## 시작하기

### 1. 환경 변수 설정

프로젝트 루트에서 예시 파일을 복사한 뒤, **본인 클러스터의 HMS, HiveServer2, Impala 주소**로 수정합니다.

```bash
cp .env.example .env
# .env 파일을 열어 REPLACE_* 자리를 실제 호스트로 바꿉니다.
# Impala: coordinator SSL 포트(예: 25003) — docs/03-cloudera-integration.md
# Hive: HMS_URI (2대), HIVESERVER2_LOAD_BALANCER (예: :10015) — 같은 문서 Beeline 절
```

### 2. Ozone volume·bucket·warehouse 준비 (최초 1회)

Iceberg 파일은 Ozone **`ofs://`** 경로에 저장됩니다. **volume과 bucket이 아직 없다면** Lab 01 전에 만들어야 합니다.

- **가이드 (CLI·UI·권한·`.env` 맞추기):** [`docs/04-ozone-storage.md`](docs/04-ozone-storage.md)  
  **Ranger가 켜져 있으면** 같은 문서 **§3**에서 **`cm_ozone` 정책** 추가 (volume/bucket/`warehouse` prefix, `systest` Read/Write/Create/Delete/List)
- **edge에서 빠른 확인/생성:**

  ```bash
  kinit -kt /cdep/keytabs/systest.keytab systest@QE-INFRA-AD.CLOUDERA.COM   # 예시
  ./scripts/setup_ozone_storage.sh --check    # 없으면 가이드 안내
  ./scripts/setup_ozone_storage.sh --apply    # 권한 있을 때 volume/bucket/warehouse 생성
  # Ranger Admin → OZONE (cm_ozone) → Add Policy — docs/04-ozone-storage.md §3
  ```

`.env`의 `OZONE_VOLUME`, `OZONE_BUCKET`, `WAREHOUSE_OFS`는 **실제로 만든 이름·경로**와 같아야 합니다.

### 3. 연결 확인

```bash
./scripts/validate.sh
```

Kerberos(`kinit`) 등이 필요하면 Lab 공통 스크립트 안내를 따릅니다.

### 4. (선택) 합성 데이터 만들기

일부 Lab은 미리 만든 Parquet 데이터를 사용합니다.

```bash
cd synthetic-data && pip install -r requirements.txt
python generators/generate_ecommerce_data.py --rows-customers 1000 --rows-orders 5000
```

## Lab 진행 순서

| 구분 | Lab 번호 | 내용 |
|------|----------|------|
| **Core (Iceberg 핵심)** | 01 → 09 | 테이블 만들기부터 파티션, 스키마 변경, MERGE, 시간 여행, 유지보수까지 |
| **Appendix (CDP·운영)** | 10 → 13 | Ozone 경로, Kerberos, Optimizer, REST Catalog 개념 |

**권장:** 번호 순서대로 진행하세요. 각 Lab README에 “선행 Lab”이 적혀 있습니다.

### 한 Lab 실행 방법

```bash
cd labs/lab-01-basic-table   # 예: Lab 01
./run.sh                     # SQL 실습 실행
./validate_all.sh            # Spark + Hive + Impala로 결과 검증
```

### 전체 Lab 한 번에

```bash
./scripts/run_all_labs.sh
```

(환경·권한에 따라 시간이 오래 걸릴 수 있습니다.)

## 프로젝트 폴더 구조

| 경로 | 초급자에게 |
|------|------------|
| `labs/lab-*/` | Lab별 SQL과 `run.sh`, `validate_all.sh` |
| `labs/common/` | 모든 Lab이 공유하는 환경 로드(`env.sh`), SQL 실행·3엔진 검증 스크립트 |
| `config/` | Ozone, Kerberos, Spark 설정 **템플릿** (클러스터에 맞게 복사·수정) |
| `docs/` | Iceberg 아키텍처, Cloudera 연동, 문제 해결 가이드 |
| `synthetic-data/` | 실습용 전자상거래 Parquet 데이터 생성기 |
| `docker/rest-catalog/` | REST Catalog를 **별도로** 띄울 때 참고 (선택) |

더 자세한 Lab 설계·프롬프트: [`PROMPT.md`](PROMPT.md)

## 자주 쓰는 용어 (짧게)

- **HMS (Hive Metastore)**: 테이블 이름, 위치, Iceberg 메타데이터 포인터 등을 저장하는 “카탈로그”
- **3엔진**: 이 Lab에서 말하는 Spark(주로 쓰기·고급 SQL), Hive, Impala(주로 읽기·검증)
- **warehouse**: Iceberg 테이블 데이터·메타데이터 파일이 저장되는 루트 경로 (여기서는 Ozone `ofs://` 사용)

각 Lab README에서 그 Lab만의 용어를 더 풀어서 설명합니다.
