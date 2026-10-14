# 03. 로드밸런서 & Auto Scaling

## 로드밸런서

| | Web 계층 | WAS 계층 |
|---|---|---|
| 타입 | ALB (internet-facing) | NLB (internal) |
| 리스너 | 443 HTTPS (ACM), 80 → 443 리다이렉트 | TCP 8080 |
| 타깃 | Web ASG : 80 | WAS ASG : 8080 |
| 헬스체크 | HTTP `/` | TCP 8080 <!-- TODO: HTTP 헬스체크로 했다면 경로 기입 --> |
| SG | `pc-sg-alb` | `pc-sg-nlb` |

> 초기에는 "외부 ALB / 내부 ALB"를 가정했으나, 내부에서는 TLS 종료·L7 라우팅이 필요하지 않다고 판단하여 **외부 ALB / 내부 NLB**로 확정했습니다.

## Launch Template

- AMI: 계층별 골든 AMI
- IAM Instance Profile: SSM + Parameter Store 읽기 + CloudWatch Agent ([04 문서](04-ssm-parameter-store.md))
- User Data: [web.sh](../scripts/user-data/web.sh) / [was.sh](../scripts/user-data/was.sh)
- 키 페어 없음 (SSM Session Manager로 접근)

## Auto Scaling Group

| | Web | WAS |
|---|---|---|
| 서브넷 | `pc-sub-web-a/c` | `pc-sub-was-a/c` |
| Min / Desired / Max | 2 / 2 / 4 | 2 / 2 / 4 |
| 스케일링 정책 | Target Tracking — Request Count 20000 | Target Tracking — CPU 60% |
| 헬스체크 | ELB | ELB |

Web / WAS ASG는 팀원 2명이 계층별로 나눠 병렬로 구축했습니다.

## 트래픽 분산 데모

<!-- TODO: 데모 영상 링크 또는 GIF (docs/images/) -->
