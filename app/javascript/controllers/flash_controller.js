import { Controller } from "@hotwired/stimulus"

// Auto-dismiss flash notifications
export default class extends Controller {
    dismiss() {
        this.element.remove()
    }

    connect() {
        // Auto-dismiss after 5 seconds for success messages
        if (this.element.classList.contains("is-success")) {
            setTimeout(() => this.element.remove(), 5000)
        }
    }
}
