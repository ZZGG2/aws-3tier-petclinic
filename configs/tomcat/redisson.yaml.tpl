# Redisson 설정 템플릿 — __REDIS_ENDPOINT__ 는 User Data가 SSM 값으로 치환
# ElastiCache Redis (클러스터 모드 비활성, Primary 엔드포인트)
singleServerConfig:
  address: "redis://__REDIS_ENDPOINT__:6379"
  connectionMinimumIdleSize: 4
  connectionPoolSize: 16
  timeout: 3000
  retryAttempts: 3
# 전송 중 암호화(TLS)를 켰다면 rediss:// 로 변경
