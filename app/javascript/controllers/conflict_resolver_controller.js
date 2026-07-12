import { Controller } from "@hotwired/stimulus"

// Drives the PR merge cockpit's conflict resolver: pick incoming/base into each
// file's result pane (or hand-edit), and only enable Merge once every conflicting
// file is resolved.
export default class extends Controller {
  static targets = ["block", "mergeBtn", "summary"]

  connect() {
    this.refresh()
  }

  // data-conflict-resolver-side-param="ours" | "theirs"
  use(event) {
    const side = event.params.side
    const block = event.target.closest("[data-conflict-block]")
    const result = block.querySelector("[data-result]")
    result.value = side === "ours" ? block.dataset.ours : block.dataset.theirs
    this.markResolved(block)
  }

  edit(event) {
    this.markResolved(event.target.closest("[data-conflict-block]"))
  }

  markResolved(block) {
    block.dataset.resolved = "true"
    block.classList.add("resolved")
    this.refresh()
  }

  refresh() {
    const blocks = this.blockTargets
    const resolved = blocks.filter((b) => b.dataset.resolved === "true").length
    const allResolved = blocks.length === 0 || resolved === blocks.length

    if (this.hasMergeBtnTarget) this.mergeBtnTarget.disabled = !allResolved
    if (this.hasSummaryTarget) {
      this.summaryTarget.textContent =
        blocks.length === 0 ? "No conflicts" : `${resolved}/${blocks.length} files resolved`
    }
  }
}
