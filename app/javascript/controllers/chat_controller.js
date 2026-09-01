import { Controller } from "@hotwired/stimulus"

// Auto-scrolls chat to bottom on connect and after new messages
export default class extends Controller {
    static targets = ["messages", "textarea", "emojiPicker", "fileInput", "attachmentsPreview"]

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

    // Show a chip per selected file, each with a remove button
    filesSelected() {
        this.renderAttachmentsPreview()
    }

    renderAttachmentsPreview() {
        if (!this.hasAttachmentsPreviewTarget || !this.hasFileInputTarget) return
        const files = Array.from(this.fileInputTarget.files || [])
        const preview = this.attachmentsPreviewTarget
        preview.innerHTML = ""
        preview.classList.toggle("d-none", files.length === 0)

        files.forEach((file, index) => {
            const chip = document.createElement("span")
            chip.className = "chat-attachment-chip"

            const name = document.createElement("span")
            name.className = "chat-attachment-chip-name"
            name.textContent = `📎 ${file.name}`
            chip.appendChild(name)

            const remove = document.createElement("button")
            remove.type = "button"
            remove.className = "chat-attachment-chip-remove"
            remove.setAttribute("aria-label", this.attachmentsPreviewTarget.dataset.removeLabel || "Remove")
            remove.textContent = "✕"
            remove.addEventListener("click", () => this.removeFile(index))
            chip.appendChild(remove)

            preview.appendChild(chip)
        })
    }

    // Native FileList is read-only, so rebuild it via DataTransfer without the removed entry
    removeFile(index) {
        const input = this.fileInputTarget
        const dt = new DataTransfer()
        Array.from(input.files).forEach((file, i) => {
            if (i !== index) dt.items.add(file)
        })
        input.files = dt.files
        this.renderAttachmentsPreview()
    }
}
