# 07. 로그 파이프라인

모든 로그를 S3 한 곳에 모아 장기 보관합니다.

```
Apache / Tomcat 로그 ──CloudWatch Agent──▶ CloudWatch Logs ──▶ S3
ALB Access Log ─────────────────────────────────────────────▶ S3
CloudTrail ─────────────────────────────────────────────────▶ S3
```

| 소스 | 수집 방식 | S3 Prefix |
|---|---|---|
| Apache access/error | CloudWatch Agent → Log Group `/pc/web/apache/*` | `cwlogs/web/` |
| Tomcat catalina/access | CloudWatch Agent → Log Group `/pc/was/tomcat/*` | `cwlogs/was/` |
| ALB | ALB 속성 – Access logs 활성화 | `alb/` |
| CloudTrail | Trail → S3 | `cloudtrail/` |

<!-- TODO: CloudWatch Logs → S3 방식(Export Task / Firehose 구독 필터) 확인 후 기입 -->

- Agent 설정: [amazon-cloudwatch-agent.json](../configs/cloudwatch/amazon-cloudwatch-agent.json)
- Private 서브넷에서 `logs`, `monitoring` Interface Endpoint로 전송 (NAT 없음)
- ALB 로그를 받으려면 S3 버킷 정책에 ELB 로그 전송 주체 허용이 필요합니다

## 버킷 운영

- 버전 관리 + 퍼블릭 액세스 차단
- Lifecycle: 30일 후 Standard-IA, 90일 후 Glacier <!-- TODO: 실제 정책 -->
