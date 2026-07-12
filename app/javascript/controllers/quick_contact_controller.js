import { Controller } from "@hotwired/stimulus"

// Toolbar "find a teammate" popover: filter the people list, then either
// video-call (a normal link) or reveal the message composer for the picked user.
export default class extends Controller {
  static targets = ["panel", "search", "item", "recipient", "recipientLabel", "compose", "messageInput"]

  toggle() {
    this.panelTarget.classList.toggle("is-hidden")
    if (!this.panelTarget.classList.contains("is-hidden")) this.searchTarget.focus()
  }

  close(event) {
    if (!this.element.contains(event.target)) this.panelTarget.classList.add("is-hidden")
  }

  filter() {
    const q = this.searchTarget.value.toLowerCase()
    this.itemTargets.forEach((el) => {
      el.classList.toggle("is-hidden", !el.dataset.name.includes(q))
    })
  }

  pick(event) {
    this.recipientTarget.value = event.params.user
    this.recipientLabelTarget.textContent = event.params.name
    this.composeTarget.classList.remove("is-hidden")
    this.messageInputTarget.focus()
  }
}
