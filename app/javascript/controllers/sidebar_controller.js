import { Controller } from "@hotwired/stimulus"

// Handles collapsible project sections + panel toggle in the sidebar
export default class extends Controller {
    static targets = ["project", "panel", "toggleButton"]

    connect() {
        this.restorePanelState()
    }

    toggleProject(event) {
        const header = event.currentTarget
        const project = header.closest(".sidebar-project")
        if (project) project.classList.toggle("is-open")
    }

    togglePanel(event) {
        if (event) event.preventDefault()

        const hidden = this.panelTarget.classList.toggle("is-hidden")
        this.toggleButtonTarget.classList.toggle("is-active", !hidden)
        localStorage.setItem("devteam.rightPanelHidden", hidden ? "1" : "0")
    }

    restorePanelState() {
        const stored = localStorage.getItem("devteam.rightPanelHidden")
        const hidden = stored !== "0"
        this.panelTarget.classList.toggle("is-hidden", hidden)
        this.toggleButtonTarget.classList.toggle("is-active", !hidden)
    }
}
