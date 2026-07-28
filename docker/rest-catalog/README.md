# REST Catalog (선택 사항)

## 이 폴더는 무엇인가요?

대부분의 Lab은 **Hive Metastore(HMS)** 에 테이블 정보를 등록하고, Spark·Hive·Impala가 그 HMS를 통해 Iceberg 테이블을 찾습니다.

**REST Catalog**는 다른 방식입니다. Iceberg가 정의한 **HTTP API**로 카탈로그(테이블 목록·메타데이터)에 접근합니다. 클라우드·멀티 클러스터·REST만 열려 있는 환경에서 자주 논의됩니다.

- **Lab 13**의 기본 실습은 여전히 **HMS 테이블 + 3엔진 검증**입니다.
- REST Catalog는 **개념 비교**와, 필요할 때 이 폴더/별도 Docker 구성을 참고하는 **심화** 주제입니다.

## 초급자가 알아두면 좋은 점

| 방식 | 비유 |
|------|------|
| HMS | “회사 전화번호부” — CDP 안 Spark/Hive/Impala가 익숙하게 쓰는 방식 |
| REST | “웹 API로 번호부 조회” — Spark catalog 설정에서 `type=rest` 로 URI·토큰 지정 |

Lab을 처음 하신다면 REST Catalog Docker를 꼭 띄울 필요는 **없습니다**.

## 실행 (클러스터 정책에 맞게)

Docker Compose 등은 **사내 보안·네트워크 정책**에 따라 허용 여부가 다릅니다. 허용된 환경에서만 아래와 같이 별도 구성합니다.

```bash
# 예: docker compose up (실제 compose 파일·이미지는 환경에 맞게 준비)
```

## Spark에서 REST Catalog에 연결 (심화)

Spark Iceberg catalog 설정 예시 개념:

- catalog `type=rest`
- REST 서버 **URI**
- 필요 시 **Bearer 토큰** (인증)

자세한 키 이름·버전별 옵션은 사용 중인 Iceberg·Spark 문서를 참고하세요. 이 저장소 Lab의 기본 경로는 HMS(`ICEBERG_CATALOG=hive_prod` 등)입니다.
