# k6 scenarios — directory layout + sample script

Scripts live in `perf/`, committed to Git. One scenario per critical user journey or hot endpoint.

```
perf/
├── scenarios/
│   ├── create-order.smoke.js
│   ├── create-order.load.js
│   └── browse-catalog.soak.js
├── lib/
│   └── auth.js              ← shared helpers (token acquisition, fixtures)
└── thresholds.js            ← shared SLO thresholds
```

## Naming + profiles

`<endpoint-or-journey>.<profile>.js` where `<profile>` is one of:
- `smoke` — 1 VU, ~30 s
- `load` — steady state at target rps
- `stress` — ramp past expected peak
- `soak` — sustained over hours

## Mandatory thresholds

Every script declares `thresholds` for `http_req_duration` (e.g. `p(95)<300`) and `http_req_failed` (e.g. `rate<0.01`); a failed threshold fails the run and the CI job.

## Sample

```javascript
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    steady: { executor: 'constant-arrival-rate', rate: 50, timeUnit: '1s', duration: '5m', preAllocatedVUs: 50 }
  },
  thresholds: {
    http_req_duration: ['p(95)<300'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.get(`${__ENV.K6_BASE_URL}/api/v1.0/orders?pageSize=20`);
  check(res, { 'status is 200': (r) => r.status === 200 });
}
```

## Operational rules

- Target environment via `K6_BASE_URL` env var — never hardcode hosts
- Authentication via shared helpers in `perf/lib/` — never embed real tokens in scripts
- CI: smoke profile runs on every PR (fast, blocking); load / stress / soak run on demand or on schedule (long, non-blocking gate)
- Output: write JSON results to a CI artifact via `--out json=results.json`; optional push to InfluxDB / Grafana for trending
- When an endpoint's expected throughput or latency budget changes, update the corresponding scenario and its thresholds in the same PR
