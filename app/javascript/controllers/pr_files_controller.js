import { Controller } from "@hotwired/stimulus"

// PR file navigator: click a file in the list to show its code panel.
export default class extends Controller {
  static targets = ["item", "panel"]

  select(event) {
    const idx = event.currentTarget.dataset.index
    this.itemTargets.forEach((el) => el.classList.toggle("active-file", el.dataset.index === idx))
    this.panelTargets.forEach((el) => el.classList.toggle("d-none", el.dataset.index !== idx))
  }
}
