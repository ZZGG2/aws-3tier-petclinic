#!/usr/bin/env bash
# SSM Parameter Store 초기 등록 (관리자 PC / CloudShell에서 실행)
# 사용: WAS_NLB_DNS=... DB_ENDPOINT=... DB_PASSWORD=... REDIS_ENDPOINT=... ./put-parameters.sh
set -euo pipefail
REGION="${AWS_REGION:-ap-northeast-2}"

put() { aws ssm put-parameter --region "$REGION" --overwrite --name "$1" --type "$2" --value "$3" >/dev/null && echo "put $1"; }

put /pc/web/was-nlb-dns     String       "${WAS_NLB_DNS:?}"
put /pc/was/db/endpoint     String       "${DB_ENDPOINT:?}"
put /pc/was/db/name         String       "${DB_NAME:-petclinic}"
put /pc/was/db/username     String       "${DB_USERNAME:-admin}"
put /pc/was/db/password     SecureString "${DB_PASSWORD:?}"
put /pc/was/redis/endpoint  String       "${REDIS_ENDPOINT:?}"
