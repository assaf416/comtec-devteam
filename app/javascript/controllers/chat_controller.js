import { Controller } from "@hotwired/stimulus"

// Auto-scrolls chat to bottom on connect and after new messages
export default class extends Controller {
    static targets = ["messages", "textarea"]

    connect() {
        this.scrollToBottom()
    }

    scrollToBottom() {
        const el = this.messagesTarget
        if (el) el.scrollTop = el.scrollHeight
    }

    // Expand textarea as user types
    autoGrow(event) {
        const ta = event.currentTarget
        ta.style.height = "auto"
        ta.style.height = Math.min(ta.scrollHeight, 160) + "px"
    }

    // Submit on Ctrl+Enter / Cmd+Enter
    keySubmit(event) {
        if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
            event.preventDefault()
            event.currentTarget.closest("form")?.requestSubmit()
        }
    }

    // After form submission, scroll to bottom
    afterSubmit() {
        requestAnimationFrame(() => this.scrollToBottom())
    }
}
