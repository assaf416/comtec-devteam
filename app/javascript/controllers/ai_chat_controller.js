import { Controller } from "@hotwired/stimulus"

// Chat with AI: scroll to the latest message and submit on Enter (Shift+Enter = newline).
export default class extends Controller {
  static targets = ["scroll", "input"]

  connect() {
    if (this.hasScrollTarget) this.scrollTarget.scrollTop = this.scrollTarget.scrollHeight
    if (this.hasInputTarget) this.inputTarget.focus()
  }

  submitOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.inputTarget.form.requestSubmit()
    }
  }
}
