# 06. DNS & TLS

## 흐름

```
가비아(도메인 구매) ──NS 위임──▶ Route 53 Hosted Zone ──Alias──▶ ALB
                                        └── ACM DNS 검증 CNAME
```

1. 가비아에서 도메인 `<DOMAIN>` 구매
2. Route 53에 Public Hosted Zone 생성 → NS 레코드 4개 확인
3. 가비아 네임서버 설정을 Route 53 NS로 변경 (전파 대기)
4. ACM(서울 리전)에서 `<DOMAIN>`, `*.<DOMAIN>` 인증서 요청 → **DNS 검증** (Route 53에 CNAME 자동 생성)
5. ALB 443 리스너에 인증서 연결, 80 → 443 리다이렉트
6. Route 53 A 레코드(Alias) → ALB

## TLS 종료 지점

| 구간 | 프로토콜 |
|---|---|
| User → ALB | **HTTPS** (ACM) |
| ALB → Apache | HTTP 80 |
| Apache → NLB → Tomcat | HTTP 8080 |

내부 구간은 VPC 안에서 SG 체인으로 격리되어 있어 ALB에서 TLS를 종료했습니다. 자체 서명 인증서 import 대신 ACM + DNS 검증을 택해 **자동 갱신**을 확보했습니다.
