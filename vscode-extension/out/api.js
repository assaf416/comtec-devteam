"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.api = void 0;
exports.getApiUrl = getApiUrl;
exports.getApiToken = getApiToken;
const https = __importStar(require("https"));
const http = __importStar(require("http"));
const vscode = __importStar(require("vscode"));
function cfg() {
    return vscode.workspace.getConfiguration("devteamHub");
}
function getApiUrl() {
    return cfg().get("apiUrl") || "http://localhost:3000";
}
function getApiToken() {
    return cfg().get("apiToken") || "";
}
function request(method, path, body) {
    return new Promise((resolve, reject) => {
        const token = getApiToken();
        if (!token) {
            reject(new Error("No API token configured. Run 'DevTeam: Setup / Configure'."));
            return;
        }
        const base = getApiUrl().replace(/\/$/, "");
        const url = new URL(`${base}/api/v1${path}`);
        const isHttps = url.protocol === "https:";
        const mod = isHttps ? https : http;
        const bodyStr = body ? JSON.stringify(body) : undefined;
        const options = {
            hostname: url.hostname,
            port: url.port || (isHttps ? 443 : 80),
            path: url.pathname + url.search,
            method,
            headers: {
                Authorization: `Bearer ${token}`,
                "Content-Type": "application/json",
                Accept: "application/json",
                ...(bodyStr ? { "Content-Length": Buffer.byteLength(bodyStr) } : {}),
            },
        };
        const req = mod.request(options, (res) => {
            let data = "";
            res.on("data", (chunk) => (data += chunk));
            res.on("end", () => {
                try {
                    const json = JSON.parse(data);
                    if ((res.statusCode ?? 0) >= 400) {
                        reject(new Error(`API error ${res.statusCode}: ${json.error || JSON.stringify(json)}`));
                    }
                    else {
                        resolve(json);
                    }
                }
                catch {
                    reject(new Error(`Invalid JSON response: ${data}`));
                }
            });
        });
        req.on("error", reject);
        req.setTimeout(8000, () => {
            req.destroy(new Error(`Request to ${url} timed out`));
        });
        if (bodyStr) {
            req.write(bodyStr);
        }
        req.end();
    });
}
// ── Public API methods ─────────────────────────────────────────────────────────
exports.api = {
    getMe: () => request("GET", "/me"),
    getTickets: (params = {}) => {
        const qs = new URLSearchParams();
        if (params.assignee) {
            qs.set("assignee", params.assignee);
        }
        if (params.status) {
            qs.set("status", params.status);
        }
        if (params.project_id) {
            qs.set("project_id", String(params.project_id));
        }
        const q = qs.toString();
        return request("GET", `/tickets${q ? "?" + q : ""}`);
    },
    getTicket: (id) => request("GET", `/tickets/${id}`),
    updateTicket: (id, attrs) => request("PATCH", `/tickets/${id}`, { ticket: attrs }),
    getProjects: () => request("GET", "/projects"),
    checkout: (ticketId, assign = true) => request("POST", "/checkout", { ticket_id: ticketId, assign }),
};
//# sourceMappingURL=api.js.map