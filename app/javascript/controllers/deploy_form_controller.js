import { Controller } from "@hotwired/stimulus"

// Repopulates the image-tag <select> with the chosen project's deployable
// CI builds. The tag map is passed in as a value: { projectId: [{tag,label}] }.
export default class extends Controller {
  static targets = ["project", "tag"]
  static values = { tags: Object }

  connect() {
    this.populate()
  }

  populate() {
    const id = this.projectTarget.value
    const tags = this.tagsValue[id] || []
    this.tagTarget.innerHTML = ""

    if (tags.length === 0) {
      const opt = document.createElement("option")
      opt.value = ""
      opt.textContent = "No passing CI builds for this project"
      this.tagTarget.appendChild(opt)
      this.tagTarget.disabled = true
      return
    }

    this.tagTarget.disabled = false
    tags.forEach((t) => {
      const opt = document.createElement("option")
      opt.value = t.tag
      opt.textContent = t.label
      this.tagTarget.appendChild(opt)
    })
  }
}
