# 09. 부하 테스트

## 도구

- **k6** — 시나리오 스크립트: [load-test/petclinic.js](../load-test/petclinic.js)
- **CloudWatch Dashboard** `pc-cw-loadtest` — ALB, ASG, RDS 지표를 한 화면에

## 시나리오

평시 50~100명, 피크 2배를 가정합니다.

| 단계 | 가상 사용자 | 시간 |
|---|---|---|
| Ramp-up | 0 → 50 | 2분 |
| 평시 | 100 | 5분 |
| 피크 | 200 | 3분 |
| Ramp-down | → 0 | 1분 |

요청 흐름: 메인 → 오너 검색 → 오너 상세 → 수의사 목록

합격 기준: `p(95) < 1s`, 에러율 `< 1%`

## 대시보드 위젯

| 영역 | 지표 |
|---|---|
| ALB | RequestCount, TargetResponseTime(p95), HTTPCode_Target_5XX |
| ASG | CPUUtilization, InServiceInstances (Web/WAS) |
| RDS | CPUUtilization, DatabaseConnections, FreeableMemory |

## 결과

### 설계 목표 (합격 기준)
| 지표 | 목표 |
|---|---|
| p95 응답시간 | < 1s |
| 에러율 | < 1% |
| 피크 부하 | 평시(100 VU)의 2배, 200 VU |
| 스케일 아웃 | CPU 50% 초과 시 ASG 자동 확장 |

### 실측 결과
| 항목 | 결과 |
|---|---|
| 총 요청 수 | 약 80,000건 |
| ALB 502 에러 | 튜닝 전 반복 발생 → **튜닝 후 0~1건 (≈0.001%)** |
| 에러율 목표(< 1%) | **충족** |

> 리소스 정리 전에 상세 지표(p95, RPS)를 보존하지 못했습니다. 이후 테스트 결과는 `load-test/results/`에 커밋하도록 절차를 바꿨습니다.