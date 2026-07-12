import * as vscode from "vscode";
import { TicketsProvider, ProjectsProvider } from "./providers/treeProviders";
import { registerCommands, updateStatusBar } from "./commands";
import { getApiToken } from "./api";

export function activate(context: vscode.ExtensionContext) {
    // ── Tree providers ───────────────────────────────────────────────────────

    const ticketsProvider = new TicketsProvider(context);
    const projectsProvider = new ProjectsProvider();

    vscode.window.createTreeView("devteam.myTickets", {
        treeDataProvider: ticketsProvider,
        showCollapseAll: true,
    });
    vscode.window.createTreeView("devteam.projects", {
        treeDataProvider: projectsProvider,
    });

    // ── Status bar ───────────────────────────────────────────────────────────

    const statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 50);
    statusBarItem.command = "devteam.status";
    context.subscriptions.push(statusBarItem);

    // ── Commands ─────────────────────────────────────────────────────────────

    registerCommands(
        context,
        () => ticketsProvider.refresh(),
        () => projectsProvider.refresh(),
        statusBarItem
    );

    // ── Auto-refresh on branch change ─────────────────────────────────────

    const watcher = vscode.workspace.createFileSystemWatcher("**/.git/HEAD");
    watcher.onDidChange(() => {
        ticketsProvider.refresh();
        updateStatusBar(statusBarItem);
    });
    context.subscriptions.push(watcher);

    // ── Config change watcher ────────────────────────────────────────────

    context.subscriptions.push(
        vscode.workspace.onDidChangeConfiguration((e) => {
            if (e.affectsConfiguration("devteamHub")) {
                ticketsProvider.refresh();
                projectsProvider.refresh();
                updateStatusBar(statusBarItem);
            }
        })
    );

    // ── Initial load ─────────────────────────────────────────────────────

    if (getApiToken()) {
        ticketsProvider.refresh();
        projectsProvider.refresh();
        updateStatusBar(statusBarItem);
    } else {
        vscode.window.showInformationMessage(
            "DevTeam Hub: Not configured.",
            "Setup"
        ).then((action) => {
            if (action === "Setup") {
                vscode.commands.executeCommand("devteam.setup");
            }
        });
    }
}

export function deactivate() {
    // nothing
}
