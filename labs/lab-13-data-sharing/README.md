# Lab 13 — Data Sharing & REST Catalog (Appendix)

**트랙:** Appendix (카탈로그·공유 개념)  
**난이도:** 초급 (개념) + 심화 (REST는 선택)

## 이 Lab에서 배우는 것

### HMS 카탈로그 (이 저장소 Lab의 기본)

- 테이블 이름·스키마·**Iceberg 메타데이터 파일 위치**가 **Hive Metastore**에 등록됩니다.
- Spark·Hive·Impala는 CDP에서 흔히 **같은 HMS**를 바라봅니다.
- **Lab 13의 실습·검증 기본:** Lab 01 등에서 만든 **HMS Iceberg 테이블**을 **3엔진**으로 다시 읽어 **공유·일관성**을 확인합니다.

### REST Catalog (개념·선택)

- 카탈로그 API를 **HTTP(REST)** 로 제공하는 Iceberg 표준 방식입니다.
- 다른 클러스터·클라우드 서비스와 **테이블 메타를 공유**할 때 논의됩니다.
- **Docker로 REST Catalog 띄우기**는 `docker/rest-catalog/README.md` 참고 — **필수 아님**, 정책·네트워크 허용 시 심화.

**초급자 한 줄 요약:** 일상 CDP 실습은 **HMS**면 충분하고, REST는 “나중에 멀티 클라우드·REST 전용 제품을 쓸 때” 알면 됩니다.

## 실행 방법

```bash
cd labs/lab-13-data-sharing
./run.sh
./validate_all.sh
```

REST 연결 예제는 Lab SQL·README 보조 문서에만 있을 수 있습니다. 기본 `validate_all.sh`는 **HMS 테이블 3엔진** 기준입니다.

## 3엔진 검증

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark / Hive / Impala** | HMS Iceberg 테이블 **SELECT/COUNT** | REST는 문서·선택 구성 |

## 선행 Lab

**Lab 01** — 공유 대상 테이블·DB가 있어야 합니다.

## Lab 코스 마무리

Core **01~09** + Appendix **10~13**을 끝냈다면:

- `docs/01-iceberg-architecture.md` — 전체 구조 복습
- `docs/troubleshooting.md` — 자주 나는 오류

를 읽으며 실무 클러스터에 적용해 보세요.
