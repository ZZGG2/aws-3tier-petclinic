# 02. 골든 AMI

## 원칙

1. **실행에 필요한 것만 굽는다** — git, Maven, mysql-client 같은 빌드·검증 도구는 넣지 않습니다.
2. **환경 값은 굽지 않는다** — NLB DNS, RDS 엔드포인트, DB 비밀번호는 부팅 시 SSM Parameter Store에서 읽습니다.
3. **데이터 영역은 별도 EBS** — 10GB 추가 볼륨을 붙여 루트와 분리합니다.

## 빌드 흐름

```
[빌더 EC2 (Public, SSH)] ──설치/설정──▶ [AMI 생성] ──▶ Launch Template ──▶ ASG (Private)
[빌드 전용 EC2] ── mvn package ──▶ petclinic.war ──scp──▶ WAS 빌더
```

| 항목 | Web | WAS |
|---|---|---|
| OS | Ubuntu | Ubuntu |
| 런타임 | Apache2 (`mod_proxy`, `mod_proxy_http`) | Tomcat 9 + Java 17 |
| 추가 EBS (10GB, ext4 통디스크) | `/var/www/html` | `/opt/tomcat` |
| 추가 도구 | AWS CLI, CloudWatch Agent | AWS CLI, CloudWatch Agent |
| 스크립트 | [web-setup.sh](../scripts/golden-ami/web-setup.sh) | [was-setup.sh](../scripts/golden-ami/was-setup.sh) |

## EBS 마운트

파티션 없이 디스크 전체를 ext4로 포맷하고 `/etc/fstab`에 **UUID + `nofail`** 로 등록합니다. AMI에서 새 인스턴스가 뜰 때 디바이스 이름(`/dev/nvme1n1` 등)이 바뀔 수 있으므로 UUID를 사용합니다.

## AMI 생성 전 체크리스트

- [ ] 서비스 enable 상태 확인 (`apache2`, `tomcat`, `amazon-cloudwatch-agent`)
- [ ] 로그/임시 파일 정리, `cloud-init clean`
- [ ] SSH 키·히스토리 등 빌더 흔적 제거
- [ ] 환경 값(엔드포인트, 비밀번호)이 파일에 남아있지 않은지 `grep` 확인
