#!/usr/bin/env bash
# Web 골든 AMI 빌드 스크립트 (Ubuntu, Public 서브넷 빌더 EC2에서 1회 실행)
# - Apache2 + mod_proxy, AWS CLI v2, CloudWatch Agent 설치
# - 추가 EBS(10GB)를 /var/www/html 에 마운트
# - 환경 값(NLB DNS)은 넣지 않음 → 부팅 시 User Data가 SSM에서 주입
set -euo pipefail

DATA_DEV="${DATA_DEV:-/dev/nvme1n1}"   # lsblk 로 확인 후 지정
MOUNT_POINT="/var/www/html"

apt-get update -y
apt-get install -y apache2 unzip curl

# --- 추가 EBS 마운트 (파티션 없이 통디스크 ext4) ---
if ! blkid "$DATA_DEV" >/dev/null 2>&1; then
  mkfs.ext4 -F "$DATA_DEV"
fi
mkdir -p "$MOUNT_POINT"
UUID=$(blkid -s UUID -o value "$DATA_DEV")
grep -q "$UUID" /etc/fstab || echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
mount -a

# --- Apache 모듈 & 가상호스트 ---
a2enmod proxy proxy_http headers
cp "$(dirname "$0")/../../configs/apache/petclinic.conf.tpl" /etc/apache2/sites-available/petclinic.conf.tpl
a2dissite 000-default || true
echo "OK" > "$MOUNT_POINT/health.html"   # ALB 헬스체크용 (선택)

# --- AWS CLI v2 ---
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp && /tmp/aws/install --update
rm -rf /tmp/aws /tmp/awscliv2.zip

# --- CloudWatch Agent ---
ARCH=$(dpkg --print-architecture)
curl -sSL "https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/${ARCH}/latest/amazon-cloudwatch-agent.deb" -o /tmp/cwagent.deb
dpkg -i /tmp/cwagent.deb && rm -f /tmp/cwagent.deb
cp "$(dirname "$0")/../../configs/cloudwatch/amazon-cloudwatch-agent.json" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

systemctl enable apache2 amazon-cloudwatch-agent

# --- AMI 생성 전 정리 ---
apt-get clean
cloud-init clean --logs
echo "Web golden AMI build done. 이제 콘솔에서 AMI를 생성하세요."
