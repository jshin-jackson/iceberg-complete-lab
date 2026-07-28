# PyIceberg (선택 실습)

## PyIceberg가 뭔가요?

**PyIceberg**는 Python에서 Iceberg 테이블을 다루는 라이브러리입니다. SQL 대신 코드로:

- 테이블 **메타데이터** 조회
- (환경에 따라) **스캔·필터** 등

을 할 수 있습니다. Spark 클러스터 없이 **엣지 노트북·로컬**에서 메타만 확인할 때 유용합니다.

## 이 Lab 예제가 하는 일

HMS(Hive Metastore) 카탈로그에 등록된 **`iceberg_lab.customers`** 테이블의 메타데이터를 PyIceberg로 읽는 **짧은 예제**입니다. Lab 01에서 만든 고객 테이블이 있어야 의미 있는 결과가 나옵니다.

## 실행 방법

PyIceberg는 Lab 필수는 **아닙니다**. 클러스터 edge 또는 HMS/HDFS·Ozone에 접근 가능한 머신에서:

```bash
pip install pyiceberg
python pyiceberg_read.py
```

연결 정보(HMS URI, warehouse 등)는 `pyiceberg_read.py`와 `.env` / 클러스터 설정을 맞춰야 합니다. Kerberos·방화벽 때문에 로컬 PC만으로는 실패할 수 있습니다.

## SQL Lab과의 관계

- **Lab 01 본편:** `./run.sh` + `./validate_all.sh` (Spark/Hive/Impala)
- **이 문서:** Python으로 같은 테이블의 “설명서(메타)”를 peek — **보조 학습**

먼저 Lab 01 SQL 실습을 끝낸 뒤 시도하는 것을 권장합니다.
