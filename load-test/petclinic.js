// k6 부하 테스트 — 동물병원 예약 서비스 시나리오 (평시 50~100명, 피크 2배)
// 실행: k6 run -e BASE_URL=https://<DOMAIN> load-test/petclinic.js
import http from 'k6/http';
import { check, sleep, group } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'https://example.com';

export const options = {
  stages: [
    { duration: '2m', target: 50 },   // ramp-up
    { duration: '5m', target: 100 },  // 평시
    { duration: '3m', target: 200 },  // 피크
    { duration: '1m', target: 0 },    // ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  group('home', () => {
    const r = http.get(`${BASE_URL}/`);
    check(r, { 'home 200': (res) => res.status === 200 });
  });
  sleep(1);

  group('find owners', () => {
    const r = http.get(`${BASE_URL}/owners?lastName=`);
    check(r, { 'owners 200': (res) => res.status === 200 });
  });
  sleep(1);

  group('owner detail', () => {
    const id = Math.floor(Math.random() * 10) + 1;
    const r = http.get(`${BASE_URL}/owners/${id}`);
    check(r, { 'owner 200': (res) => res.status === 200 });
  });
  sleep(1);

  group('vets', () => {
    const r = http.get(`${BASE_URL}/vets`);
    check(r, { 'vets 200': (res) => res.status === 200 });
  });
  sleep(2);
}
