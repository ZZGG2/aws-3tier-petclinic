# 05. 데이터베이스 & 세션

## RDS MySQL

| 항목 | 값 |
|---|---|
| 엔진 | MySQL 8.0 |
| 배포 | **Multi-AZ** (초기 Single-AZ → 최종 Multi-AZ) |
| 초기 DB | `petclinic` |
| 인스턴스 클래스 | `<TODO: db.t3.micro / db.t4g.small 등>` |
| 백업 | Automated Backup (일 1회 스냅샷 + 트랜잭션 로그 → PITR) |
| 서브넷 그룹 | `pc-sub-db-a/c` |

### 인스턴스 클래스 선정 근거

"일단 크게 띄우고 줄이기"는 허용하지 않는다는 조건에서, 서비스 시나리오로 사이징했습니다.

- 시나리오: 동물병원 예약 서비스, 평시 동시 사용자 **50~100명**
- 주요 부하: 예약 조회/등록 위주의 짧은 트랜잭션
- 검증: k6 부하 테스트 중 RDS CPU·커넥션·Freeable Memory 관찰 ([09 문서](09-load-test.md))

<!-- TODO: 선택한 클래스와 부하 테스트에서 확인한 수치(최대 CPU %, 커넥션 수)로 3줄 정도 근거 작성 -->

### JDBC 프로필

PetClinic 기본 H2 대신 MySQL 프로필로 실행합니다. 엔드포인트·계정은 Tomcat 기동 시 Parameter Store에서 읽어 JVM 옵션으로 주입합니다 → [setenv.sh](../configs/tomcat/setenv.sh)

## ElastiCache Redis — 세션 공유

### 배경

WAS가 ASG로 여러 대일 때 세션이 인스턴스 메모리에 있으면, 스케일 인 또는 NLB 분산으로 다른 WAS에 붙는 순간 로그인이 풀립니다. PetClinic에 로그인 기능은 없지만 **인프라 관점에서 로그인 서비스를 가정**하고 세션 저장소를 외부화했습니다.

### 제약 & 해결

- 제약: GitHub `main` 코드(`pom.xml` 포함) 수정 금지
- 해결: **Redisson Tomcat Session Manager** — Tomcat `lib/`에 jar를 넣고 `context.xml`에 Manager만 등록 → 애플리케이션 무수정

설정: [context.xml](../configs/tomcat/context.xml), [redisson.yaml.tpl](../configs/tomcat/redisson.yaml.tpl)
