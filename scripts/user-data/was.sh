#!/bin/bash
# WAS Launch Template User Data
# - Redis 엔드포인트를 SSM에서 읽어 redisson.yaml 렌더링
# - DB 접속 정보는 Tomcat 기동 시 setenv.sh가 SSM에서 직접 조회
set -euo pipefail

TOMCAT_HOME=/opt/tomcat
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

REDIS_ENDPOINT=$(aws ssm get-parameter --region "$REGION" --name /pc/was/redis/endpoint --query Parameter.Value --output text)

sed "s|__REDIS_ENDPOINT__|${REDIS_ENDPOINT}|g" \
  "$TOMCAT_HOME/conf/redisson.yaml.tpl" > "$TOMCAT_HOME/conf/redisson.yaml"
chown tomcat:tomcat "$TOMCAT_HOME/conf/redisson.yaml"
chmod 640 "$TOMCAT_HOME/conf/redisson.yaml"

echo "AWS_REGION=${REGION}" > /etc/default/tomcat
systemctl restart tomcat

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
