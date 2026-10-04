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

<!-- TODO: k6 summary 캡처 + 대시보드 캡처, 스케일 아웃 발생 시점, RDS 최대 CPU -->

| 지표 | 결과 |
|---|---|
| p95 응답시간 | |
| 에러율 | |
| 최대 RPS | |
| 스케일 아웃 | |
| RDS 최대 CPU | |
