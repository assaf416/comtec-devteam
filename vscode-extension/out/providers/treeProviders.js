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
exports.ProjectsProvider = exports.TicketsProvider = exports.StatusGroupItem = exports.ProjectItem = exports.TicketItem = void 0;
const vscode = __importStar(require("vscode"));
const api_1 = require("../api");
// ─── Status icons ──────────────────────────────────────────────────────────────
const STATUS_ICON = {
    open: "$(circle-outline)",
    backlog: "$(dash)",
    in_progress: "$(play)",
    in_review: "$(eye)",
    done: "$(check)",
    cancelled: "$(x)",
};
const PRIORITY_COLOR = {
    critical: new vscode.ThemeColor("charts.red"),
    high: new vscode.ThemeColor("charts.yellow"),
    medium: new vscode.ThemeColor("charts.blue"),
    low: new vscode.ThemeColor("charts.purple"),
};
// ─── Tree items ───────────────────────────────────────────────────────────────
class TicketItem extends vscode.TreeItem {
    constructor(ticket) {
        const icon = STATUS_ICON[ticket.status] ?? "$(circle-outline)";
        super(`${icon} T-${ticket.id}: ${ticket.title}`, vscode.TreeItemCollapsibleState.None);
        this.ticket = ticket;
        this.contextValue = "ticket";
        this.description = `${ticket.priority.toUpperCase()} · ${ticket.project.name}`;
        this.tooltip = new vscode.MarkdownString(`**T-${ticket.id}** — ${ticket.title}\n\n` +
            `- Status: ${ticket.status}\n` +
            `- Priority: ${ticket.priority}\n` +
            `- Project: ${ticket.project.name}\n` +
            (ticket.branch_name ? `- Branch: \`${ticket.branch_name}\`\n` : "") +
            (ticket.description ? `\n${ticket.description.substring(0, 200)}` : ""));
        const color = PRIORITY_COLOR[ticket.priority];
        if (color) {
            this.iconPath = new vscode.ThemeIcon("circle-filled", color);
        }
        // Open ticket in browser on click
        this.command = {
            command: "devteam.ticketShow",
            title: "Show Ticket",
            arguments: [ticket],
        };
    }
}
exports.TicketItem = TicketItem;
class ProjectItem extends vscode.TreeItem {
    constructor(project) {
        super(project.name, vscode.TreeItemCollapsibleState.Collapsed);
        this.project = project;
        this.contextValue = "project";
        this.description = `${project.open_tickets} open`;
        this.iconPath = new vscode.ThemeIcon("repo");
        this.tooltip = `${project.name}\n${project.tech_stack}\n${project.open_tickets} open tickets`;
    }
}
exports.ProjectItem = ProjectItem;
class StatusGroupItem extends vscode.TreeItem {
    constructor(label, tickets) {
        super(`${label} (${tickets.length})`, vscode.TreeItemCollapsibleState.Expanded);
        this.label = label;
        this.tickets = tickets;
        this.contextValue = "group";
    }
}
exports.StatusGroupItem = StatusGroupItem;
// ─── Tickets Tree Provider ────────────────────────────────────────────────────
class TicketsProvider {
    constructor(context) {
        this.context = context;
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
        this.tickets = [];
        this.loading = false;
    }
    refresh() {
        this._onDidChangeTreeData.fire();
    }
    getTreeItem(el) {
        return el;
    }
    async getChildren(parent) {
        if (parent instanceof StatusGroupItem) {
            return parent.tickets.map((t) => new TicketItem(t));
        }
        if (parent) {
            return [];
        }
        // Root: fetch tickets grouped by status
        try {
            this.tickets = await api_1.api.getTickets({ assignee: "me" });
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            vscode.window.showWarningMessage(`DevTeam: ${msg}`);
            return [];
        }
        if (this.tickets.length === 0) {
            return [];
        }
        // Group by status
        const order = ["in_progress", "in_review", "open", "backlog", "done"];
        const groups = new Map();
        for (const t of this.tickets) {
            if (!groups.has(t.status)) {
                groups.set(t.status, []);
            }
            groups.get(t.status).push(t);
        }
        return order
            .filter((s) => groups.has(s) && groups.get(s).length > 0)
            .map((s) => new StatusGroupItem(s.replace(/_/g, " ").toUpperCase(), groups.get(s)));
    }
}
exports.TicketsProvider = TicketsProvider;
// ─── Projects Tree Provider ───────────────────────────────────────────────────
class ProjectsProvider {
    constructor() {
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
    }
    refresh() {
        this._onDidChangeTreeData.fire();
    }
    getTreeItem(el) {
        return el;
    }
    async getChildren(parent) {
        if (parent instanceof ProjectItem) {
            return [];
        }
        if (parent) {
            return [];
        }
        try {
            const projects = await api_1.api.getProjects();
            return projects.map((p) => new ProjectItem(p));
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            vscode.window.showWarningMessage(`DevTeam: ${msg}`);
            return [];
        }
    }
}
exports.ProjectsProvider = ProjectsProvider;
//# sourceMappingURL=treeProviders.js.map