import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["parent", "subrule"]

  connect() {
    this.element.addEventListener("change", this.handleChange.bind(this))
  }

  handleChange(event) {
    const target = event.target
    // If a subrule is checked, check its parent
    if (this.subruleTargets.includes(target) && target.checked) {
      const parentId = target.dataset.parentId
      const parent = this.parentTargets.find(cb => cb.id === parentId)
      if (parent) parent.checked = true
    }
    // If a parent is unchecked, uncheck all its subrules
    if (this.parentTargets.includes(target) && !target.checked) {
      this.subruleTargets.forEach(checkbox => {
        if (checkbox.dataset.parentId === target.id) checkbox.checked = false
      })
    }
  }
}
