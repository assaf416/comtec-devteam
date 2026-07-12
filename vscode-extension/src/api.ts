import * as https from "https";
import * as http from "http";
import * as vscode from "vscode";

export interface Ticket {
    id: number;
    title: string;
    description: string;
    status: string;
    priority: string;
    kind: string;
    level: string;
    how_to_reproduce?: string;
    pr_number?: number;
    pr_url?: string;
    dev_estimate_hours?: number;
    tester_estimate_hours?: number;
    branch_name?: string;
    project: { id: number; name: string; repo_url: string; default_branch: string };
    assignee?: { id: number; name: string } | null;
    owner?: { id: number; name: string } | null;
}

export interface Project {
    id: number;
    name: string;
    repo_url: string;
    default_branch: string;
    tech_stack: string;
    active: boolean;
    open_tickets: number;
}

export interface CurrentUser {
    id: number;
    name: string;
    email: string;
    role: string;
    api_token: string;
    tickets: number;
    projects: Array<{ id: number; name: string }>;
}

function cfg() {
    return vscode.workspace.getConfiguration("devteamHub");
}

export function getApiUrl(): string {
    return cfg().get<string>("apiUrl") || "http://localhost:3000";
}

export function getApiToken(): string {
    return cfg().get<string>("apiToken") || "";
}

function request<T>(
    method: "GET" | "POST" | "PATCH",
    path: string,
    body?: object
): Promise<T> {
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

        const options: http.RequestOptions = {
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
                    } else {
                        resolve(json as T);
                    }
                } catch {
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

export const api = {
    getMe: () => request<CurrentUser>("GET", "/me"),

    getTickets: (params: {
        assignee?: "me";
        status?: string;
        project_id?: number;
    } = {}) => {
        const qs = new URLSearchParams();
        if (params.assignee) { qs.set("assignee", params.assignee); }
        if (params.status) { qs.set("status", params.status); }
        if (params.project_id) { qs.set("project_id", String(params.project_id)); }
        const q = qs.toString();
        return request<Ticket[]>("GET", `/tickets${q ? "?" + q : ""}`);
    },

    getTicket: (id: number) => request<Ticket>("GET", `/tickets/${id}`),

    updateTicket: (id: number, attrs: Partial<Pick<Ticket, "status" | "priority" | "pr_number" | "pr_url">>) =>
        request<Ticket>("PATCH", `/tickets/${id}`, { ticket: attrs }),

    getProjects: () => request<Project[]>("GET", "/projects"),

    checkout: (ticketId: number, assign = true) =>
        request<{ branch: string; ticket_id: number; title: string; repo_url: string; base: string }>(
            "POST",
            "/checkout",
            { ticket_id: ticketId, assign }
        ),
};
