import { Controller } from "@hotwired/stimulus"

// Drives the Log Viewer: refreshes the console on filter changes and supports a
// live "watch" mode that polls the tail endpoint on an interval.
export default class extends Controller {
  static targets = ["form", "console", "watchButton"]
  static values  = { url: String, interval: { type: Number, default: 4000 } }

  disconnect() {
    this.stopWatch()
  }

  // Re-fetch the log lines using the current filter values (no full page reload).
  submit(event) {
    if (event) event.preventDefault()
    this.refresh()
  }

  toggleWatch() {
    this.timer ? this.stopWatch() : this.startWatch()
  }

  startWatch() {
    this.refresh()
    this.timer = setInterval(() => this.refresh(), this.intervalValue)
    if (this.hasWatchButtonTarget) {
      this.watchButtonTarget.textContent = "⏸ Watching…"
      this.watchButtonTarget.classList.add("btn-success")
      this.watchButtonTarget.classList.remove("btn-secondary")
    }
  }

  stopWatch() {
    if (this.timer) clearInterval(this.timer)
    this.timer = null
    if (this.hasWatchButtonTarget) {
      this.watchButtonTarget.textContent = "▶ Watch"
      this.watchButtonTarget.classList.remove("btn-success")
      this.watchButtonTarget.classList.add("btn-secondary")
    }
  }

  async refresh() {
    const params = new URLSearchParams(new FormData(this.formTarget))
    try {
      const response = await fetch(`${this.urlValue}?${params.toString()}`, {
        headers: { "X-Requested-With": "XMLHttpRequest" }
      })
      if (!response.ok) return
      const wasAtBottom = this.isScrolledToBottom()
      this.consoleTarget.innerHTML = await response.text()
      if (this.timer || wasAtBottom) this.scrollToBottom()
    } catch (_e) {
      // Network/Loki hiccup — keep the current view, try again next tick.
    }
  }

  isScrolledToBottom() {
    const el = this.consoleTarget
    return el.scrollHeight - el.scrollTop - el.clientHeight < 40
  }

  scrollToBottom() {
    this.consoleTarget.scrollTop = this.consoleTarget.scrollHeight
  }
}
