# 08. 백업 & 재해 복구

## 목표

| 지표 | 목표 | 근거 |
|---|---|---|
| **RTO** | 3시간 | 예약 서비스 특성상 수 시간 중단은 전화 예약으로 대체 가능 |
| **RPO** | 10분 | 예약 데이터 유실 최소화 — RDS PITR(트랜잭션 로그 약 5분 단위)로 충족 |

## 장애 시나리오별 대응

| 장애 | 대응 | 복구 방식 |
|---|---|---|
| Web/WAS 인스턴스 장애 | ELB 헬스체크 실패 → ASG 자동 교체 | 자동 (수 분) |
| AZ 장애 | 다른 AZ 인스턴스로 트래픽 이동, ASG가 남은 AZ에 재배치 | 자동 |
| RDS Primary 장애 | Multi-AZ 자동 Failover (엔드포인트 동일) | 자동 (1~2분) |
| 데이터 손상/오삭제 | Automated Backup으로 **특정 시점 복원(PITR)** → 새 인스턴스 → Parameter Store 엔드포인트 교체 → WAS 인스턴스 새로고침 | 수동 (RTO 내) |
| 인프라 전체 손실 | 골든 AMI + Launch Template + 문서화된 절차로 재구축 | 수동 |

> 엔드포인트를 Parameter Store로 관리하기 때문에, DB 복원 후 **파라미터 값 하나만 바꾸고 ASG Instance Refresh**를 돌리면 WAS가 새 DB를 바라봅니다.

## DR 데모

<!-- TODO: 장애 주입(인스턴스 종료 / RDS 재부팅 with failover) 데모 영상 링크 -->
