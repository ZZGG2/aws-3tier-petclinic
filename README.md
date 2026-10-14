# AWS 3-Tier PetClinic Infrastructure

> Spring PetClinic을 **동물병원 예약 서비스**로 가정하고, AWS 위에 고가용성·보안·관측성을 갖춘 3-Tier 인프라를 설계·구축한 팀 프로젝트입니다.
> Bespin Global 클라우드 엔지니어 양성 과정 (KDT) 최종 프로젝트 · 4인 팀

<!-- TODO: 전체 아키텍처 이미지 추가 -> docs/images/architecture.png -->
<!-- ![Architecture](docs/images/architecture.png) -->

## 한눈에 보기

| 항목 | 내용 |
|---|---|
| 서비스 시나리오 | 동물병원 예약 서비스 (평시 동시 사용자 50~100명) |
| 애플리케이션 | [Spring Framework PetClinic (팀 포크)](https://github.com/TEAM-24-7/petclinic_btc) — WAR, Tomcat 9 |
| 구성 | 2 AZ × 4 Tier (Public / Web / WAS / DB), 서브넷 8개 |
| 진입점 | Route 53 → ALB (HTTPS, ACM) → Apache → 내부 NLB → Tomcat → RDS MySQL |
| 접근 방식 | Bastion 없이 **SSM Session Manager** |
| 외부 통신 | NAT Gateway 대신 **VPC Endpoint** |
| 세션 | **ElastiCache Redis** 세션 공유 (애플리케이션 코드 수정 없이 WAS 설정만으로) |
| 로그 | Apache/Tomcat/ALB/CloudTrail 로그 → CloudWatch → **S3** |
| 목표 | **RTO 3시간 / RPO 10분** |

## 아키텍처

<p align="center">
  <img src="docs/images/architecture.png" alt="Architecture" width="900">
</p>

## 핵심 설계 결정

| 결정 | 선택 | 이유 |
|---|---|---|
| 인스턴스 접근 | SSM Session Manager | SSH 포트·Bastion 제거, IAM 기반 접근 제어와 세션 감사 |
| LB 구성 | Web: 외부 ALB / WAS: 내부 NLB | L7 라우팅·TLS 종료는 ALB, 내부 구간은 단순 TCP 분산 |
| Web→WAS 연결 | Apache `mod_proxy` (HTTP) | mod_jk(AJP)는 단일 WAS 직결 구조라 NLB 경유 확장에 불리 |
| 설정 주입 | SSM Parameter Store + User Data | 골든 AMI에 엔드포인트/비밀번호를 굽지 않음 → 환경 간 재사용 |
| 골든 AMI | 실행에 필요한 것만 포함 | git/Maven/mysql-client 제외, WAR는 별도 빌드 EC2에서 생성 |
| 외부 통신 | VPC Endpoint | NAT 비용 절감, 트래픽이 AWS 내부망으로만 흐름 |
| 세션 | Redis (Redisson Tomcat Session Manager) | ASG 스케일 인/아웃 시에도 로그인 세션 유지, 앱 코드 무수정 |
| DB | RDS MySQL Multi-AZ + Automated Backup | 장애 시 자동 Failover, RPO 목표 충족 |

자세한 근거: [docs/decisions.md](docs/decisions.md)

## 문서

| # | 문서 | 내용 |
|---|---|---|
| 1 | [네트워크](docs/01-network.md) | VPC, 서브넷, 라우팅, 보안그룹 체인, VPC Endpoint |
| 2 | [골든 AMI](docs/02-golden-ami.md) | Web/WAS 이미지 빌드, EBS 마운트 |
| 3 | [로드밸런서 & Auto Scaling](docs/03-load-balancing-asg.md) | ALB/NLB, Launch Template, ASG |
| 4 | [설정 관리 (SSM)](docs/04-ssm-parameter-store.md) | Parameter Store 구조, IAM Role |
| 5 | [데이터베이스 & 세션](docs/05-rds-redis.md) | RDS 사이징 근거, Redis 세션 |
| 6 | [DNS & TLS](docs/06-dns-tls.md) | 가비아 → Route 53 위임, ACM |
| 7 | [로그 파이프라인](docs/07-logging.md) | CloudWatch Agent, S3 적재 |
| 8 | [백업 & DR](docs/08-backup-dr.md) | RTO/RPO, 장애 시나리오 |
| 9 | [부하 테스트](docs/09-load-test.md) | k6 시나리오, CloudWatch 대시보드 |
| - | [트러블슈팅](docs/troubleshooting.md) | 구축 중 겪은 문제와 해결 |

## 레포 구조

```
.
├── README.md
├── docs/                    # 단계별 구축 문서, 설계 결정, 트러블슈팅
├── scripts/
│   ├── golden-ami/          # 골든 AMI 빌드 스크립트 (web / was)
│   ├── user-data/           # Launch Template User Data (web / was)
│   └── ssm/                 # Parameter Store 등록 스크립트
├── configs/
│   ├── apache/              # mod_proxy 가상호스트
│   ├── tomcat/              # setenv.sh, Redisson 세션 설정
│   └── cloudwatch/          # CloudWatch Agent 설정
└── load-test/               # k6 스크립트
```

## 기술 스택

`AWS VPC` `EC2` `Auto Scaling` `ALB` `NLB` `RDS (MySQL 8.0)` `ElastiCache (Valkey)` `Route 53` `ACM` `SSM` `CloudWatch` `CloudTrail` `S3` `Apache2` `Tomcat 9` `Java 17` `k6`

## 팀

| 이름 | 역할 | GitHub |
|---|---|---|
| 배대석 | WEB, WAS 등 전반 인프라 구성 | https://github.com/ZZGG2/ |
| 송준욱 | 네트워크, 보안 구성 | https://github.com/msugr/ |
| 김은지 | RDS, Redis 등 데이터베이스 구성 | https://github.com/didhddl49/ |
| 이요섭 | CloudWatch 모니터링 구성 | https://github.com/bbben2/ |

## 회고

### 잘한 점
- **ALB 502 에러 해결** — 부하 테스트 중 반복된 ALB 502를 Apache 설정 튜닝으로 약 8만 건 요청당 0~1건 수준까지 낮췄습니다. 지표와 로그로 원인을 좁혀 가는 과정을 경험했습니다. ([트러블슈팅](docs/troubleshooting.md))
- **설정과 이미지 분리** — 엔드포인트와 비밀번호를 SSM Parameter Store로 옮겨, 같은 골든 AMI를 어느 환경에서나 다시 쓸 수 있게 했습니다.
- **근거 있는 사이징** — "크게 띄웠다가 줄이기"를 하지 않기로 하고, 서비스 시나리오(평시 50~100명)와 k6 결과로 RDS 클래스를 정했습니다.

### 아쉬운 점
- **콘솔 수동 구축의 한계** — v1/v2를 함께 운영하면서 LB를 다시 만들었을 때 파라미터가 따라오지 않는 설정 드리프트가 생겼고, 결국 전체를 다시 구축했습니다. 어떤 변경이 있었는지 추적할 수 없다는 점이 가장 큰 비용이었습니다.
- **재현성 부족** — 대부분 콘솔에서 작업해 스크립트와 설정이 거의 남지 않았고, 이 레포를 정리하면서 구성을 다시 만들어야 했습니다.

### 다음에 적용할 것
- **IaC(Terraform)로 처음부터 구성** — 변경 이력을 남기고, 재구축을 명령 한 번으로 끝낼 수 있게
- **CI/CD로 WAR 빌드와 AMI 생성 자동화** (GitHub Actions + Packer)
- **멀티 클라우드로 재해 복구** — AWS 외부에서도 재해 복구할 수 있는 시나리오
- **MSA 기반 아키텍처** - Docker, k8s 도입으로 아키텍처 세분화