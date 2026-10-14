# 트러블슈팅

구축 중 겪은 주요 문제와 해결 과정입니다. 자세한 분석은 Velog 글에 정리했습니다.

## ALB 502 Bad Gateway

- **증상**: k6 부하 테스트 중 ALB에서 502가 간헐적으로 반복 발생
- **원인**: Apache KeepAlive 타임아웃이 ALB idle timeout보다 짧아, ALB가 이미 닫힌 연결을 재사용
- **해결**: 블로그 참조
- **결과**: 약 80,000건 요청 중 502 **0~1건**

📝 **자세히 보기** → [ALB 502 트러블슈팅](https://velog.io/@tkdxm0208/ALB-502-TroubleShooting)
