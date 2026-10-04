# 설계 결정 기록 (ADR)

## ADR-1. Bastion Host 대신 SSM Session Manager
- **상황**: Private 인스턴스 접근 필요
- **결정**: Bastion 없이 Session Manager 사용
- **결과**: 22번 포트·키 페어 관리 제거, IAM으로 접근 제어, 세션 이력 감사 가능. 단 SSM 관련 VPC Endpoint 3종이 필요

## ADR-2. 외부 ALB + 내부 NLB
- **상황**: 초기 설계는 외부 NLB / 내부 ALB
- **결정**: 외부 ALB(TLS 종료, HTTP 리다이렉트) / 내부 NLB(TCP 8080)
- **결과**: 사용자 앞단에서 L7 기능 활용, 내부는 단순·저지연. NLB에 SG를 붙여 WAS SG를 SG 참조로 잠금

## ADR-3. mod_jk(AJP) → mod_proxy(HTTP)
- **상황**: v1(Tomcat 9 + mod_jk 단일 WAS 직결)과 v2(HTTP 리버스 프록시 + NLB)를 병행
- **결정**: 최종은 mod_proxy로 NLB 경유
- **결과**: WAS를 ASG로 확장해도 Apache 설정 변경 불필요. AJP 커넥터 노출 위험(Ghostcat 계열) 회피

## ADR-4. 설정은 Parameter Store, AMI는 불변
- **상황**: LB 재생성 후 하드코딩된 DNS와 실제 리소스 불일치(드리프트)
- **결정**: 환경 값은 전부 Parameter Store, 부팅 시 IAM Role로 조회
- **결과**: 같은 AMI를 어떤 환경에서도 재사용, 비밀번호가 이미지/스크립트에 남지 않음

## ADR-5. 전체 재구축 (2026-09-19)
- **상황**: 콘솔 수동 변경 누적으로 v1/v2 리소스·파라미터 정합성 붕괴
- **결정**: 기존 VPC/RDS 유지안 폐기, VPC부터 재구축. 리소스 접두사 `pc-` 통일
- **결과**: 명명 규칙·SG 체인 정리. **IaC 도입 필요성**을 회고 항목으로 도출

## ADR-6. NAT Gateway → VPC Endpoint
- **상황**: Private 인스턴스의 외부 통신 대상은 AWS 서비스(SSM, CloudWatch, S3)뿐
- **결정**: NAT 제거, Interface/Gateway Endpoint 구성
- **결과**: NAT 시간당·데이터 처리 비용 제거, 트래픽이 인터넷을 거치지 않음. 런타임 패키지 설치 불가 → 골든 AMI에서 해결

## ADR-7. Redis 세션 (앱 코드 무수정)
- **상황**: ASG 환경에서 세션 유지 필요, main 브랜치 코드 수정 금지
- **결정**: Redisson Tomcat Session Manager를 WAS 설정으로만 적용
- **결과**: 스케일 인/아웃·인스턴스 교체에도 세션 유지
