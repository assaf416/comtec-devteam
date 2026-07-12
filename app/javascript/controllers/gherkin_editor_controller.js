import { Controller } from "@hotwired/stimulus"

// Lightweight Gherkin syntax highlighting: a coloured <pre> rendered behind a
// transparent <textarea> overlay (kept in sync on input + scroll).
export default class extends Controller {
  static targets = ["input", "highlight"]

  connect() { this.render() }

  render() {
    this.highlightTarget.innerHTML = this.highlight(this.inputTarget.value)
    this.sync()
  }

  sync() {
    this.highlightTarget.scrollTop = this.inputTarget.scrollTop
    this.highlightTarget.scrollLeft = this.inputTarget.scrollLeft
  }

  highlight(text) {
    let html = text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")

    // Per-line keyword highlighting. Class attributes use single quotes so the
    // double-quote string matcher below can't accidentally match them.
    html = html.split("\n").map((line) => {
      if (/^\s*#/.test(line)) return `<span class='gh-comment'>${line}</span>`
      if (/^\s*@/.test(line)) return `<span class='gh-tag'>${line}</span>`
      line = line.replace(/^(\s*)(Feature|Background|Rule|Scenario Outline|Scenario|Examples):/,
        "$1<span class='gh-feature'>$2:</span>")
      line = line.replace(/^(\s*)(Given|When|Then|And|But)\b/,
        "$1<span class='gh-step'>$2</span>")
      return line
    }).join("\n")

    // Inline tokens: double-quoted strings and <placeholders>.
    html = html.replace(/"[^"]*"/g, (m) => `<span class='gh-string'>${m}</span>`)
    html = html.replace(/&lt;[^&<>]+?&gt;/g, (m) => `<span class='gh-param'>${m}</span>`)

    return html + "\n"
  }
}
