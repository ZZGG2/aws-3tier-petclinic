# 01. 네트워크
## VPC & 서브넷

- 리전: `ap-northeast-2` (서울), AZ: `2a`, `2c`
- VPC: `pc-vpc` — `10.0.0.0/16`
- 2 AZ × 4 Tier = 서브넷 8개

| Tier | AZ-a | AZ-c | 라우팅 |
|---|---|---|---|
| Public | `pc-sub-public-a` 10.0.1.0/24 | `pc-sub-public-c` 10.0.2.0/24 | IGW |
| Web | `pc-sub-web-a` 10.0.11.0/24 | `pc-sub-web-c` 10.0.12.0/24 | local + VPC Endpoint |
| WAS | `pc-sub-was-a` 10.0.21.0/24 | `pc-sub-was-c` 10.0.22.0/24 | local + VPC Endpoint |
| DB | `pc-sub-db-a` 10.0.31.0/24 | `pc-sub-db-c` 10.0.32.0/24 | local |
| Valkey | `pc-sub-valkey-a` 10.0.41.0/24 | `pc-sub-valkey-c` 10.0.42.0/24 | local |

## 보안그룹 체인

각 계층은 **바로 앞 계층의 보안그룹만** 인바운드로 허용합니다 (IP가 아닌 SG 참조).

```
Internet ──80/443──▶ pc-sg-alb ──80──▶ pc-sg-web ──8080──▶ pc-sg-nlb ──8080──▶ pc-sg-was ──3306──▶ pc-sg-db
                                                                                    └──6379──▶ pc-sg-redis
```

| SG | 인바운드 | 용도 |
|---|---|---|
| `pc-sg-public` | 80 Any, 22 MyIP | 골든 AMI 빌더 (Public) |
| `pc-sg-alb` | 80, 443 Any | 외부 ALB |
| `pc-sg-web` | 80 from `pc-sg-alb` | Apache |
| `pc-sg-nlb` | TCP 8080 from `pc-sg-web` | 내부 NLB (생성 시 SG 연결) |
| `pc-sg-was` | 8080 from `pc-sg-nlb` | Tomcat |
| `pc-sg-db` | 3306 from `pc-sg-was` | RDS |
| `pc-sg-valkey` | 6379 from `pc-sg-was` | ElastiCache |
| `pc-sg-vpce` | 443 from VPC CIDR | Interface Endpoint |

> NLB는 생성 시점에만 SG를 붙일 수 있어 처음부터 `pc-sg-nlb`를 지정했습니다. WAS SG를 NLB SG 참조로 묶을 수 있는 이유이기도 합니다.

## NAT Gateway → VPC Endpoint

초기에는 단일 NAT Gateway로 구성했으나, 최종 설계에서는 Private 인스턴스가 인터넷이 아니라 **AWS 서비스에만** 접근하면 된다는 점에 착안해 VPC Endpoint로 대체했습니다. 패키지 설치는 Public 서브넷의 골든 AMI 빌더에서 끝나므로 런타임에는 인터넷이 필요 없습니다.

| Endpoint | 타입 | 용도 |
|---|---|---|
| `com.amazonaws.ap-northeast-2.ssm` | Interface | Parameter Store, Session Manager |
| `...ssmmessages` | Interface | Session Manager |
| `...ec2messages` | Interface | SSM Agent |
| `...logs` | Interface | CloudWatch Logs (Agent) |
| `...monitoring` | Interface | CloudWatch 메트릭 (Agent) |
| `...s3` | Gateway | S3 (로그 적재 등) |
