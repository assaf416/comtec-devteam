import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["tbody", "row", "key", "val"]

    addRow() {
        const existingRows = this.tbodyTarget.querySelectorAll("tr")
        const idx = existingRows.length
        const row = document.createElement("tr")
        row.dataset.envVarsTarget = "row"
        row.innerHTML = `
      <td class="ps-3 py-2">
        <input type="text" name="deployment[env_vars][${idx}][key]"
               class="form-control form-control-sm font-monospace"
               placeholder="VARIABLE_NAME"
               data-env-vars-target="key">
      </td>
      <td class="py-2">
        <input type="text" name="deployment[env_vars][${idx}][value]"
               class="form-control form-control-sm font-monospace"
               placeholder="value"
               data-env-vars-target="val">
      </td>
      <td class="py-2 pe-2 text-center">
        <button type="button" class="btn btn-sm btn-outline-danger px-2"
                data-action="click->env-vars#removeRow"
                title="Remove">
          <i class="bi bi-trash3"></i>
        </button>
      </td>
    `
        this.tbodyTarget.appendChild(row)
        row.querySelector("input").focus()
        this._reindex()
    }

    removeRow(event) {
        event.currentTarget.closest("tr").remove()
        this._reindex()
    }

    // Re-number all row indices so params stay consistent
    _reindex() {
        this.tbodyTarget.querySelectorAll("tr").forEach((row, i) => {
            row.querySelectorAll("input[name]").forEach(input => {
                input.name = input.name.replace(/\[\d+\]/, `[${i}]`)
            })
        })
    }
}
