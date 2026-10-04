# Apache 가상호스트 템플릿 — __WAS_NLB_DNS__ 는 User Data가 SSM 값으로 치환
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html

    # ALB 헬스체크는 Apache가 직접 응답 (WAS 장애가 Web 교체로 번지지 않도록)
    ProxyPass        /health.html !

    ProxyPreserveHost On
    ProxyTimeout 60
    ProxyPass        / http://__WAS_NLB_DNS__:8080/ retry=0 connectiontimeout=5
    ProxyPassReverse / http://__WAS_NLB_DNS__:8080/

    # ALB가 넘겨준 원 프로토콜을 WAS에 전달
    RequestHeader set X-Forwarded-Proto "https"

    ErrorLog  ${APACHE_LOG_DIR}/petclinic_error.log
    CustomLog ${APACHE_LOG_DIR}/petclinic_access.log combined
</VirtualHost>
