import * as vscode from "vscode";
import { Ticket, Project, api } from "../api";

// ─── Status icons ──────────────────────────────────────────────────────────────

const STATUS_ICON: Record<string, string> = {
    open: "$(circle-outline)",
    backlog: "$(dash)",
    in_progress: "$(play)",
    in_review: "$(eye)",
    done: "$(check)",
    cancelled: "$(x)",
};

const PRIORITY_COLOR: Record<string, vscode.ThemeColor> = {
    critical: new vscode.ThemeColor("charts.red"),
    high: new vscode.ThemeColor("charts.yellow"),
    medium: new vscode.ThemeColor("charts.blue"),
    low: new vscode.ThemeColor("charts.purple"),
};

// ─── Tree items ───────────────────────────────────────────────────────────────

export class TicketItem extends vscode.TreeItem {
    constructor(public readonly ticket: Ticket) {
        const icon = STATUS_ICON[ticket.status] ?? "$(circle-outline)";
        super(`${icon} T-${ticket.id}: ${ticket.title}`, vscode.TreeItemCollapsibleState.None);

        this.contextValue = "ticket";
        this.description = `${ticket.priority.toUpperCase()} · ${ticket.project.name}`;
        this.tooltip = new vscode.MarkdownString(
            `**T-${ticket.id}** — ${ticket.title}\n\n` +
            `- Status: ${ticket.status}\n` +
            `- Priority: ${ticket.priority}\n` +
            `- Project: ${ticket.project.name}\n` +
            (ticket.branch_name ? `- Branch: \`${ticket.branch_name}\`\n` : "") +
            (ticket.description ? `\n${ticket.description.substring(0, 200)}` : "")
        );

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

export class ProjectItem extends vscode.TreeItem {
    constructor(public readonly project: Project) {
        super(project.name, vscode.TreeItemCollapsibleState.Collapsed);
        this.contextValue = "project";
        this.description = `${project.open_tickets} open`;
        this.iconPath = new vscode.ThemeIcon("repo");
        this.tooltip = `${project.name}\n${project.tech_stack}\n${project.open_tickets} open tickets`;
    }
}

export class StatusGroupItem extends vscode.TreeItem {
    constructor(
        public readonly label: string,
        public readonly tickets: Ticket[]
    ) {
        super(`${label} (${tickets.length})`, vscode.TreeItemCollapsibleState.Expanded);
        this.contextValue = "group";
    }
}

type TreeNode = TicketItem | ProjectItem | StatusGroupItem;

// ─── Tickets Tree Provider ────────────────────────────────────────────────────

export class TicketsProvider implements vscode.TreeDataProvider<TreeNode> {
    private _onDidChangeTreeData = new vscode.EventEmitter<TreeNode | undefined | void>();
    readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

    private tickets: Ticket[] = [];
    private loading = false;

    constructor(private readonly context: vscode.ExtensionContext) { }

    refresh(): void {
        this._onDidChangeTreeData.fire();
    }

    getTreeItem(el: TreeNode): vscode.TreeItem {
        return el;
    }

    async getChildren(parent?: TreeNode): Promise<TreeNode[]> {
        if (parent instanceof StatusGroupItem) {
            return parent.tickets.map((t) => new TicketItem(t));
        }

        if (parent) {
            return [];
        }

        // Root: fetch tickets grouped by status
        try {
            this.tickets = await api.getTickets({ assignee: "me" });
        } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : String(err);
            vscode.window.showWarningMessage(`DevTeam: ${msg}`);
            return [];
        }

        if (this.tickets.length === 0) {
            return [];
        }

        // Group by status
        const order = ["in_progress", "in_review", "open", "backlog", "done"];
        const groups = new Map<string, Ticket[]>();
        for (const t of this.tickets) {
            if (!groups.has(t.status)) { groups.set(t.status, []); }
            groups.get(t.status)!.push(t);
        }

        return order
            .filter((s) => groups.has(s) && groups.get(s)!.length > 0)
            .map((s) => new StatusGroupItem(s.replace(/_/g, " ").toUpperCase(), groups.get(s)!));
    }
}

// ─── Projects Tree Provider ───────────────────────────────────────────────────

export class ProjectsProvider implements vscode.TreeDataProvider<TreeNode> {
    private _onDidChangeTreeData = new vscode.EventEmitter<TreeNode | undefined | void>();
    readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

    refresh(): void {
        this._onDidChangeTreeData.fire();
    }

    getTreeItem(el: TreeNode): vscode.TreeItem {
        return el;
    }

    async getChildren(parent?: TreeNode): Promise<TreeNode[]> {
        if (parent instanceof ProjectItem) {
            return [];
        }
        if (parent) { return []; }

        try {
            const projects = await api.getProjects();
            return projects.map((p) => new ProjectItem(p));
        } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : String(err);
            vscode.window.showWarningMessage(`DevTeam: ${msg}`);
            return [];
        }
    }
}
