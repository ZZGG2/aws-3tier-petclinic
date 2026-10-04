#!/usr/bin/env bash
# WAS 골든 AMI 빌드 스크립트 (Ubuntu, Public 서브넷 빌더 EC2에서 1회 실행)
# - Java 17 + Tomcat 9 (/opt/tomcat, 추가 EBS), AWS CLI v2, CloudWatch Agent
# - Redisson Tomcat Session Manager jar 배치
# - git / Maven / mysql-client 는 설치하지 않음 (WAR는 별도 빌드 EC2에서 scp)
# - DB/Redis 엔드포인트·비밀번호는 넣지 않음 → 기동 시 SSM에서 조회
set -euo pipefail

DATA_DEV="${DATA_DEV:-/dev/nvme1n1}"         # lsblk 로 확인 후 지정
TOMCAT_HOME="/opt/tomcat"
TOMCAT_VERSION="${TOMCAT_VERSION:-9.0.121}"  # 프로젝트에서 사용한 버전
REDISSON_VERSION="${REDISSON_VERSION:-3.27.2}"
WAR_PATH="${WAR_PATH:-/tmp/petclinic.war}"   # 빌드 EC2에서 scp 해 둔 WAR

apt-get update -y
apt-get install -y openjdk-17-jre-headless unzip curl

# --- tomcat 사용자 ---
id tomcat >/dev/null 2>&1 || useradd -r -m -U -d "$TOMCAT_HOME" -s /bin/false tomcat

# --- 추가 EBS 마운트 ---
if ! blkid "$DATA_DEV" >/dev/null 2>&1; then
  mkfs.ext4 -F "$DATA_DEV"
fi
mkdir -p "$TOMCAT_HOME"
UUID=$(blkid -s UUID -o value "$DATA_DEV")
grep -q "$UUID" /etc/fstab || echo "UUID=$UUID $TOMCAT_HOME ext4 defaults,nofail 0 2" >> /etc/fstab
mount -a

# --- Tomcat 9 설치 ---
curl -sSL "https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" -o /tmp/tomcat.tgz
tar -xzf /tmp/tomcat.tgz -C "$TOMCAT_HOME" --strip-components=1
rm -f /tmp/tomcat.tgz
rm -rf "$TOMCAT_HOME"/webapps/{docs,examples,host-manager,manager,ROOT}

# --- 설정 파일 ---
CONF_DIR="$(dirname "$0")/../../configs/tomcat"
cp "$CONF_DIR/setenv.sh"          "$TOMCAT_HOME/bin/setenv.sh"
cp "$CONF_DIR/context.xml"        "$TOMCAT_HOME/conf/context.xml"
cp "$CONF_DIR/redisson.yaml.tpl"  "$TOMCAT_HOME/conf/redisson.yaml.tpl"
cp "$CONF_DIR/tomcat.service"     /etc/systemd/system/tomcat.service
chmod +x "$TOMCAT_HOME/bin/setenv.sh"

# --- Redisson Session Manager (Tomcat 9) ---
MVN=https://repo1.maven.org/maven2/org/redisson
curl -sSL "$MVN/redisson-all/${REDISSON_VERSION}/redisson-all-${REDISSON_VERSION}.jar"         -o "$TOMCAT_HOME/lib/redisson-all-${REDISSON_VERSION}.jar"
curl -sSL "$MVN/redisson-tomcat-9/${REDISSON_VERSION}/redisson-tomcat-9-${REDISSON_VERSION}.jar" -o "$TOMCAT_HOME/lib/redisson-tomcat-9-${REDISSON_VERSION}.jar"

# --- WAR 배포 (ROOT 컨텍스트) ---
cp "$WAR_PATH" "$TOMCAT_HOME/webapps/ROOT.war"

chown -R tomcat:tomcat "$TOMCAT_HOME"

# --- AWS CLI v2 ---
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp && /tmp/aws/install --update
rm -rf /tmp/aws /tmp/awscliv2.zip

# --- CloudWatch Agent ---
ARCH=$(dpkg --print-architecture)
curl -sSL "https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/${ARCH}/latest/amazon-cloudwatch-agent.deb" -o /tmp/cwagent.deb
dpkg -i /tmp/cwagent.deb && rm -f /tmp/cwagent.deb
cp "$(dirname "$0")/../../configs/cloudwatch/amazon-cloudwatch-agent.json" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

systemctl daemon-reload
systemctl enable tomcat amazon-cloudwatch-agent
# 빌더에는 Redis/RDS가 없으므로 여기서는 Tomcat을 기동하지 않음

apt-get clean
cloud-init clean --logs
echo "WAS golden AMI build done. 이제 콘솔에서 AMI를 생성하세요."
