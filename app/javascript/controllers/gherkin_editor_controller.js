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
    // Feature-level keywords, English + Hebrew. Longer Hebrew phrases first so
    // "תבנית תרחיש" wins over "תרחיש".
    const featureKw = "Feature|Background|Rule|Scenario Outline|Scenario|Examples" +
      "|תכונה|רקע|כלל|תבנית תרחיש|תרחיש|דוגמא|דוגמאות"
    // Step keywords, English + Hebrew. "אזי" before "אז".
    const stepKw = "Given|When|Then|And|But" +
      "|בהינתן|כאשר|אזי|אז|וגם|אבל"

    const featureRe = new RegExp(`^(\\s*)(${featureKw}):`)
    // Hebrew keywords have no word boundary against Hebrew letters, so require a
    // following space or end-of-line instead of \b.
    const stepRe = new RegExp(`^(\\s*)(${stepKw})(\\s|$)`)

    html = html.split("\n").map((line) => {
      if (/^\s*#/.test(line)) return `<span class='gh-comment'>${line}</span>`
      if (/^\s*@/.test(line)) return `<span class='gh-tag'>${line}</span>`
      line = line.replace(featureRe, "$1<span class='gh-feature'>$2:</span>")
      line = line.replace(stepRe, "$1<span class='gh-step'>$2</span>$3")
      return line
    }).join("\n")

    // Inline tokens: double-quoted strings and <placeholders>.
    html = html.replace(/"[^"]*"/g, (m) => `<span class='gh-string'>${m}</span>`)
    html = html.replace(/&lt;[^&<>]+?&gt;/g, (m) => `<span class='gh-param'>${m}</span>`)

    return html + "\n"
  }
}
