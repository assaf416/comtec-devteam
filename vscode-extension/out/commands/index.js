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
exports.registerCommands = registerCommands;
exports.updateStatusBar = updateStatusBar;
const vscode = __importStar(require("vscode"));
const cp = __importStar(require("child_process"));
const api_1 = require("../api");
const treeProviders_1 = require("../providers/treeProviders");
// ─── Helpers ──────────────────────────────────────────────────────────────────
function cfg() {
    return vscode.workspace.getConfiguration("devteamHub");
}
function cliPath() {
    const p = cfg().get("cliPath") || "";
    return p || "devteam"; // fallback to PATH
}
function runInTerminal(cmd, name = "DevTeam") {
    const terminal = vscode.window.createTerminal({ name });
    terminal.show(false);
    terminal.sendText(cmd);
    return terminal;
}
async function pickTicket(tickets) {
    const items = tickets.map((t) => ({
        label: `T-${t.id}: ${t.title}`,
        description: `${t.status} · ${t.priority} · ${t.project.name}`,
        ticket: t,
    }));
    const picked = await vscode.window.showQuickPick(items, {
        placeHolder: "Select a ticket",
        matchOnDescription: true,
    });
    return picked?.ticket;
}
const STATUS_OPTIONS = [
    { label: "$(circle-outline) open", value: "open" },
    { label: "$(dash) backlog", value: "backlog" },
    { label: "$(play) in_progress", value: "in_progress" },
    { label: "$(eye) in_review", value: "in_review" },
    { label: "$(check) done", value: "done" },
    { label: "$(x) cancelled", value: "cancelled" },
];
// ─── Command registrations ────────────────────────────────────────────────────
function registerCommands(context, ticketsRefresh, projectsRefresh, statusBarItem) {
    const reg = (id, fn) => context.subscriptions.push(vscode.commands.registerCommand(id, fn));
    // ── setup ────────────────────────────────────────────────────────────────
    reg("devteam.setup", async () => {
        const url = await vscode.window.showInputBox({
            prompt: "DevTeam Hub URL",
            value: cfg().get("apiUrl") || "http://localhost:3000",
            ignoreFocusOut: true,
        });
        if (!url) {
            return;
        }
        const token = await vscode.window.showInputBox({
            prompt: `API token — visit ${url}/api/v1/token`,
            password: true,
            ignoreFocusOut: true,
        });
        if (!token) {
            return;
        }
        await cfg().update("apiUrl", url, vscode.ConfigurationTarget.Global);
        await cfg().update("apiToken", token, vscode.ConfigurationTarget.Global);
        try {
            const user = await api_1.api.getMe();
            vscode.window.showInformationMessage(`DevTeam: Authenticated as ${user.name} (${user.role})`);
            ticketsRefresh();
            projectsRefresh();
            updateStatusBar(statusBarItem);
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            vscode.window.showErrorMessage(`DevTeam: Auth failed — ${msg}`);
        }
    });
    // ── whoami ───────────────────────────────────────────────────────────────
    reg("devteam.whoami", async () => {
        try {
            const user = await api_1.api.getMe();
            vscode.window.showInformationMessage(`DevTeam Hub | ${user.name} (${user.role}) | ${user.tickets} open tickets | Projects: ${user.projects.map((p) => p.name).join(", ")}`);
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            vscode.window.showErrorMessage(`DevTeam: ${msg}`);
        }
    });
    // ── checkout ─────────────────────────────────────────────────────────────
    reg("devteam.checkout", async () => {
        const input = await vscode.window.showInputBox({
            prompt: "Ticket ID to checkout (e.g. 5)",
            placeHolder: "42",
            validateInput: (v) => /^\d+$/.test(v) ? undefined : "Enter a numeric ticket ID",
        });
        if (!input) {
            return;
        }
        await vscode.window.withProgress({ location: vscode.ProgressLocation.Notification, title: `DevTeam: Checking out T-${input}...` }, async () => {
            try {
                const info = await api_1.api.checkout(parseInt(input, 10));
                runInTerminal(`# DevTeam: checkout T-${info.ticket_id}\ngit fetch origin ${info.base} --quiet && git checkout -B ${info.branch} origin/${info.base}`, `DevTeam: T-${info.ticket_id}`);
                vscode.window.showInformationMessage(`DevTeam: Branch ready → ${info.branch}`);
                ticketsRefresh();
                updateStatusBar(statusBarItem);
            }
            catch (err) {
                const msg = err instanceof Error ? err.message : String(err);
                vscode.window.showErrorMessage(`DevTeam checkout: ${msg}`);
            }
        });
    });
    // ── ticketList ───────────────────────────────────────────────────────────
    reg("devteam.ticketList", async () => {
        try {
            const tickets = await api_1.api.getTickets({ assignee: "me" });
            const picked = await pickTicket(tickets.filter((t) => t.status !== "done"));
            if (picked) {
                vscode.commands.executeCommand("devteam.ticketShow", picked);
            }
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            vscode.window.showErrorMessage(`DevTeam: ${msg}`);
        }
    });
    // ── ticketShow ───────────────────────────────────────────────────────────
    reg("devteam.ticketShow", async (ticketOrItem) => {
        let ticket;
        if (ticketOrItem instanceof treeProviders_1.TicketItem) {
            ticket = ticketOrItem.ticket;
        }
        else if (typeof ticketOrItem === "object" && ticketOrItem !== null && "id" in ticketOrItem) {
            ticket = ticketOrItem;
        }
        else {
            const input = await vscode.window.showInputBox({
                prompt: "Ticket ID",
                placeHolder: "42",
            });
            if (!input) {
                return;
            }
            try {
                ticket = await api_1.api.getTicket(parseInt(input, 10));
            }
            catch (err) {
                const msg = err instanceof Error ? err.message : String(err);
                vscode.window.showErrorMessage(`DevTeam: ${msg}`);
                return;
            }
        }
        // Show in a webview panel
        const panel = vscode.window.createWebviewPanel("devteam.ticket", `T-${ticket.id}: ${ticket.title}`, vscode.ViewColumn.Beside, { enableScripts: false });
        panel.webview.html = renderTicketHtml(ticket);
    });
    // ── ticketUpdate ─────────────────────────────────────────────────────────
    reg("devteam.ticketUpdate", async (arg) => {
        let ticket;
        if (arg instanceof treeProviders_1.TicketItem) {
            ticket = arg.ticket;
        }
        else {
            const tickets = await api_1.api.getTickets({ assignee: "me" }).catch(() => []);
            ticket = await pickTicket(tickets);
        }
        if (!ticket) {
            return;
        }
        const picked = await vscode.window.showQuickPick(STATUS_OPTIONS, {
            placeHolder: `Current: ${ticket.status} — select new status`,
        });
        if (!picked) {
            return;
        }
        try {
            await api_1.api.updateTicket(ticket.id, { status: picked.value });
            vscode.window.showInformationMessage(`DevTeam: T-${ticket.id} → ${picked.value}`);
            ticketsRefresh();
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            vscode.window.showErrorMessage(`DevTeam: ${msg}`);
        }
    });
    // ── ticketStart ──────────────────────────────────────────────────────────
    reg("devteam.ticketStart", async (arg) => {
        let ticket;
        if (arg instanceof treeProviders_1.TicketItem) {
            ticket = arg.ticket;
        }
        else {
            const tickets = await api_1.api.getTickets({ assignee: "me" }).catch(() => []);
            ticket = await pickTicket(tickets.filter((t) => !["in_progress", "done"].includes(t.status)));
        }
        if (!ticket) {
            return;
        }
        await vscode.window.withProgress({ location: vscode.ProgressLocation.Notification, title: `Starting T-${ticket.id}...` }, async () => {
            try {
                const info = await api_1.api.checkout(ticket.id);
                await api_1.api.updateTicket(ticket.id, { status: "in_progress" });
                runInTerminal(`git fetch origin ${info.base} --quiet && git checkout -B ${info.branch} origin/${info.base}`, `DevTeam: T-${ticket.id}`);
                vscode.window.showInformationMessage(`DevTeam: Started T-${ticket.id} on ${info.branch}`);
                ticketsRefresh();
                updateStatusBar(statusBarItem);
            }
            catch (err) {
                const msg = err instanceof Error ? err.message : String(err);
                vscode.window.showErrorMessage(`DevTeam: ${msg}`);
            }
        });
    });
    // ── ticketDone ───────────────────────────────────────────────────────────
    reg("devteam.ticketDone", async (arg) => {
        let ticket;
        if (arg instanceof treeProviders_1.TicketItem) {
            ticket = arg.ticket;
        }
        else {
            const tickets = await api_1.api.getTickets({ assignee: "me" }).catch(() => []);
            ticket = await pickTicket(tickets.filter((t) => t.status !== "done"));
        }
        if (!ticket) {
            return;
        }
        await api_1.api.updateTicket(ticket.id, { status: "done" });
        vscode.window.showInformationMessage(`DevTeam: T-${ticket.id} marked done ✓`);
        ticketsRefresh();
        updateStatusBar(statusBarItem);
    });
    // ── test ─────────────────────────────────────────────────────────────────
    reg("devteam.test", async () => {
        const options = [
            { label: "$(beaker) Run all tests", cmd: "bin/rails test" },
            { label: "$(file) Run current file tests", cmd: "bin/rails test ${relativeFile}" },
            { label: "$(symbol-method) Run with watch", cmd: "bin/rails test --verbose" },
        ];
        const picked = await vscode.window.showQuickPick(options, { placeHolder: "Select test run" });
        if (!picked) {
            return;
        }
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? ".";
        const activeFile = vscode.window.activeTextEditor?.document.uri.fsPath ?? "";
        const relativeFile = activeFile.replace(workspaceFolder + "/", "");
        const cmd = picked.cmd.replace("${relativeFile}", relativeFile);
        runInTerminal(`cd ${workspaceFolder} && ${cmd}`, "DevTeam: Tests");
    });
    // ── runServer ────────────────────────────────────────────────────────────
    reg("devteam.runServer", () => {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? ".";
        runInTerminal(`cd ${workspaceFolder} && bin/rails server`, "DevTeam: Server");
    });
    // ── stopServer ───────────────────────────────────────────────────────────
    reg("devteam.stopServer", () => {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? ".";
        runInTerminal(`lsof -ti :3000 | xargs kill -9 2>/dev/null; echo "Server stopped."`, "DevTeam");
    });
    // ── deploy ───────────────────────────────────────────────────────────────
    reg("devteam.deploy", async () => {
        const env = await vscode.window.showQuickPick([
            { label: "$(server) Staging", value: "staging" },
            { label: "$(rocket) Production", value: "production" },
        ], { placeHolder: "Deploy to..." });
        if (!env) {
            return;
        }
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? ".";
        const cli = cliPath();
        runInTerminal(`cd ${workspaceFolder} && ruby ${cli} deploy ${env.value}`, `DevTeam: Deploy ${env.value}`);
    });
    // ── pr ───────────────────────────────────────────────────────────────────
    reg("devteam.pr", () => {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? ".";
        const cli = cliPath();
        runInTerminal(`cd ${workspaceFolder} && ruby ${cli} pr`, "DevTeam: PR");
    });
    // ── openInBrowser ────────────────────────────────────────────────────────
    reg("devteam.openInBrowser", () => {
        vscode.env.openExternal(vscode.Uri.parse((0, api_1.getApiUrl)()));
    });
    // ── status ───────────────────────────────────────────────────────────────
    reg("devteam.status", async () => {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? ".";
        const cli = cliPath();
        runInTerminal(`cd ${workspaceFolder} && ruby ${cli} status`, "DevTeam: Status");
    });
    // ── refreshTickets ───────────────────────────────────────────────────────
    reg("devteam.refreshTickets", () => {
        ticketsRefresh();
        projectsRefresh();
    });
}
// ─── Status bar ───────────────────────────────────────────────────────────────
async function updateStatusBar(item) {
    try {
        const branch = await gitCurrentBranch();
        const match = branch?.match(/(?:feature|bugfix|hotfix|chore)\/T-(\d+)/);
        if (match) {
            const id = parseInt(match[1], 10);
            const ticket = await api_1.api.getTicket(id);
            const icon = { open: "○", backlog: "·", in_progress: "►", in_review: "◎", done: "✓" }[ticket.status] ?? "?";
            item.text = `${icon} T-${id}: ${ticket.title.substring(0, 30)}`;
            item.tooltip = `${ticket.status} · ${ticket.priority} · ${ticket.project.name}`;
            item.command = "devteam.ticketShow";
            item.show();
        }
        else {
            item.hide();
        }
    }
    catch {
        item.hide();
    }
}
function gitCurrentBranch() {
    return new Promise((resolve) => {
        cp.exec("git rev-parse --abbrev-ref HEAD", (err, stdout) => {
            resolve(err ? undefined : stdout.trim());
        });
    });
}
// ─── Ticket HTML webview ─────────────────────────────────────────────────────
function renderTicketHtml(t) {
    const esc = (s) => (s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    const PRIORITY_BADGE = {
        critical: "#ef4444",
        high: "#f59e0b",
        medium: "#3b82f6",
        low: "#8b5cf6",
    };
    const pColor = PRIORITY_BADGE[t.priority] ?? "#6b7280";
    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  body { font-family: var(--vscode-font-family); color: var(--vscode-editor-foreground);
         background: var(--vscode-editor-background); padding: 1.5rem; max-width: 800px; }
  h1 { font-size: 1.25rem; margin-bottom: 0.5rem; }
  .meta { display: flex; flex-wrap: wrap; gap: 0.5rem; margin-bottom: 1.5rem; }
  .badge { display: inline-block; padding: 0.15rem 0.5rem; border-radius: 9999px;
           font-size: 0.75rem; font-weight: 600; color: #fff; }
  .section { margin-bottom: 1.5rem; }
  .section h2 { font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.05em;
                opacity: 0.6; margin-bottom: 0.4rem; }
  pre { background: var(--vscode-textBlockQuote-background); padding: 0.75rem;
        border-radius: 4px; font-size: 0.85rem; white-space: pre-wrap; }
  table { border-collapse: collapse; width: 100%; }
  td { padding: 0.3rem 0.75rem; border-bottom: 1px solid var(--vscode-editorGroup-border); }
  td:first-child { opacity: 0.6; white-space: nowrap; width: 140px; }
</style>
</head>
<body>
  <h1>T-${t.id}: ${esc(t.title)}</h1>

  <div class="meta">
    <span class="badge" style="background:${pColor}">${esc(t.priority.toUpperCase())}</span>
    <span class="badge" style="background:#6b7280">${esc(t.status.replace(/_/g, " "))}</span>
    <span class="badge" style="background:#1d4ed8">${esc(t.kind)}</span>
    <span class="badge" style="background:#065f46">${esc(t.level)}</span>
  </div>

  <div class="section">
    <table>
      <tr><td>Project</td><td>${esc(t.project.name)}</td></tr>
      <tr><td>Assignee</td><td>${esc(t.assignee?.name ?? "—")}</td></tr>
      <tr><td>Branch</td><td><code>${esc(t.branch_name ?? "—")}</code></td></tr>
      ${t.pr_url ? `<tr><td>PR</td><td><a href="${esc(t.pr_url)}">#${t.pr_number}</a></td></tr>` : ""}
      <tr><td>Dev est.</td><td>${t.dev_estimate_hours ? t.dev_estimate_hours + "h" : "—"}</td></tr>
      <tr><td>QA est.</td><td>${t.tester_estimate_hours ? t.tester_estimate_hours + "h" : "—"}</td></tr>
    </table>
  </div>

  ${t.description ? `
  <div class="section">
    <h2>Description</h2>
    <pre>${esc(t.description)}</pre>
  </div>` : ""}

  ${t.how_to_reproduce ? `
  <div class="section">
    <h2>How to Reproduce</h2>
    <pre>${esc(t.how_to_reproduce)}</pre>
  </div>` : ""}
</body>
</html>`;
}
//# sourceMappingURL=index.js.map