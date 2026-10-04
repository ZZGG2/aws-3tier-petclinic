# 04. 설정 관리 — SSM Parameter Store

## 왜 Parameter Store인가

초기 v1/v2 병행 시기에 로드밸런서를 콘솔에서 삭제·재생성하면서 **스크립트에 하드코딩된 DNS와 실제 리소스가 어긋나는 설정 드리프트**를 겪었습니다. 이후 모든 환경 값을 Parameter Store로 모으고, 인스턴스는 부팅 시 IAM Role로 읽어오도록 바꿨습니다.

## 파라미터 구조

| 이름 | 타입 | 사용처 |
|---|---|---|
| `/pc/web/was-nlb-dns` | String | Apache `ProxyPass` 대상 |
| `/pc/was/db/endpoint` | String | JDBC URL |
| `/pc/was/db/name` | String | `petclinic` |
| `/pc/was/db/username` | String | JDBC |
| `/pc/was/db/password` | SecureString | JDBC |
| `/pc/was/redis/endpoint` | String | Redisson 세션 |

등록 스크립트: [put-parameters.sh](../scripts/ssm/put-parameters.sh)

<!-- TODO: 실제 파라미터 이름과 다르면 수정 (스크립트·User Data도 함께) -->

## IAM Role (Instance Profile)

- `AmazonSSMManagedInstanceCore` — Session Manager
- `CloudWatchAgentServerPolicy` — 로그/메트릭 전송
- 인라인 정책 — 자기 계층 경로만 읽기 (최소 권한)

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"],
    "Resource": "arn:aws:ssm:ap-northeast-2:<ACCOUNT_ID>:parameter/pc/was/*"
  }]
}
```

> SecureString은 기본 키(`aws/ssm`) 사용 시 별도 KMS 권한 없이 `--with-decryption`으로 읽을 수 있습니다. CMK를 쓰면 `kms:Decrypt` 추가가 필요합니다.
