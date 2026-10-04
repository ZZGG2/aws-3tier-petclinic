#!/bin/sh
# Tomcat 기동 시 SSM Parameter Store에서 DB 접속 정보를 조회해 JVM 시스템 프로퍼티로 주입
# (AMI·파일에 엔드포인트/비밀번호를 남기지 않기 위함)
# spring-framework-petclinic 의 jdbc.* 프로퍼티는 시스템 프로퍼티가 우선 적용됨

REGION="${AWS_REGION:-ap-northeast-2}"
p() { aws ssm get-parameter --region "$REGION" --name "$1" ${2:+--with-decryption} --query Parameter.Value --output text; }

DB_ENDPOINT=$(p /pc/was/db/endpoint)
DB_NAME=$(p /pc/was/db/name)
DB_USER=$(p /pc/was/db/username)
DB_PASS=$(p /pc/was/db/password decrypt)

CATALINA_OPTS="$CATALINA_OPTS -Xms512m -Xmx1024m"
CATALINA_OPTS="$CATALINA_OPTS -Djdbc.driverClassName=com.mysql.cj.jdbc.Driver"
CATALINA_OPTS="$CATALINA_OPTS -Djdbc.url=jdbc:mysql://${DB_ENDPOINT}:3306/${DB_NAME}?useUnicode=true&characterEncoding=UTF-8&serverTimezone=Asia/Seoul"
CATALINA_OPTS="$CATALINA_OPTS -Djdbc.username=${DB_USER}"
CATALINA_OPTS="$CATALINA_OPTS -Djdbc.password=${DB_PASS}"
export CATALINA_OPTS

# 참고: 비밀번호가 ps 출력에 보일 수 있음 — 운영 환경이라면 JNDI DataSource/Secrets Manager 고려
# TODO: 실제 프로젝트의 프로퍼티 키/프로필(spring.profiles.active 등)과 맞는지 확인
