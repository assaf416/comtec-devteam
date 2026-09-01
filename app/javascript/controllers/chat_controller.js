import { Controller } from "@hotwired/stimulus"

// Auto-scrolls chat to bottom on connect and after new messages
export default class extends Controller {
    static targets = ["messages", "textarea", "emojiPicker"]

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

    toggleEmojiPicker() {
        if (this.hasEmojiPickerTarget) this.emojiPickerTarget.classList.toggle("d-none")
    }

    // Insert the clicked emoji at the current cursor position in the textarea
    insertEmoji(event) {
        const emoji = event.currentTarget.textContent.trim()
        const ta = this.textareaTarget
        const start = ta.selectionStart
        const end = ta.selectionEnd
        ta.value = ta.value.slice(0, start) + emoji + ta.value.slice(end)
        ta.selectionStart = ta.selectionEnd = start + emoji.length
        ta.focus()
        if (this.hasEmojiPickerTarget) this.emojiPickerTarget.classList.add("d-none")
    }
}
