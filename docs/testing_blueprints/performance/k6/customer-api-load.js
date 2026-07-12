import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
    stages: [
        { duration: "1m", target: 20 },
        { duration: "3m", target: 80 },
        { duration: "2m", target: 80 },
        { duration: "1m", target: 0 },
    ],
    thresholds: {
        http_req_failed: ["rate<0.01"],
        http_req_duration: ["p(95)<350"],
    },
};

export default function () {
    const payload = JSON.stringify({
        name: `Load Test ${__VU}-${__ITER}`,
        email: `load-${__VU}-${__ITER}@acme.test`,
    });

    const params = {
        headers: {
            "Content-Type": "application/json",
            Authorization: "Bearer replace-with-token",
        },
    };

    const response = http.post("http://localhost:3000/api/v1/customers", payload, params);

    check(response, {
        "status is 201": (r) => r.status === 201,
        "response under 500ms": (r) => r.timings.duration < 500,
    });

    sleep(1);
}
