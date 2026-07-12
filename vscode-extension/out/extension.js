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
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const treeProviders_1 = require("./providers/treeProviders");
const commands_1 = require("./commands");
const api_1 = require("./api");
function activate(context) {
    // ── Tree providers ───────────────────────────────────────────────────────
    const ticketsProvider = new treeProviders_1.TicketsProvider(context);
    const projectsProvider = new treeProviders_1.ProjectsProvider();
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
    (0, commands_1.registerCommands)(context, () => ticketsProvider.refresh(), () => projectsProvider.refresh(), statusBarItem);
    // ── Auto-refresh on branch change ─────────────────────────────────────
    const watcher = vscode.workspace.createFileSystemWatcher("**/.git/HEAD");
    watcher.onDidChange(() => {
        ticketsProvider.refresh();
        (0, commands_1.updateStatusBar)(statusBarItem);
    });
    context.subscriptions.push(watcher);
    // ── Config change watcher ────────────────────────────────────────────
    context.subscriptions.push(vscode.workspace.onDidChangeConfiguration((e) => {
        if (e.affectsConfiguration("devteamHub")) {
            ticketsProvider.refresh();
            projectsProvider.refresh();
            (0, commands_1.updateStatusBar)(statusBarItem);
        }
    }));
    // ── Initial load ─────────────────────────────────────────────────────
    if ((0, api_1.getApiToken)()) {
        ticketsProvider.refresh();
        projectsProvider.refresh();
        (0, commands_1.updateStatusBar)(statusBarItem);
    }
    else {
        vscode.window.showInformationMessage("DevTeam Hub: Not configured.", "Setup").then((action) => {
            if (action === "Setup") {
                vscode.commands.executeCommand("devteam.setup");
            }
        });
    }
}
function deactivate() {
    // nothing
}
//# sourceMappingURL=extension.js.map