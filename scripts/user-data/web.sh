#!/bin/bash
# Web Launch Template User Data
# SSM Parameter Store에서 WAS NLB DNS를 읽어 Apache 가상호스트를 렌더링
set -euo pipefail

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

NLB_DNS=$(aws ssm get-parameter --region "$REGION" --name /pc/web/was-nlb-dns --query Parameter.Value --output text)

sed "s|__WAS_NLB_DNS__|${NLB_DNS}|g" \
  /etc/apache2/sites-available/petclinic.conf.tpl > /etc/apache2/sites-available/petclinic.conf

a2ensite petclinic
apachectl configtest
systemctl restart apache2

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
