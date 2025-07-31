import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["firstFinisher", "score", "saveButton"]
  connect() {
    this.checkButton()

    this.scoreTargets.forEach(input => {
      input.addEventListener('keyup', () => this.checkButton());
    });

    if (this.hasFirstFinisherTarget) {
      this.firstFinisherTarget.addEventListener('change', () => this.checkButton());
    }
  }

  closeModalAfterSuccess(event) {
    window.my_modal_3.close()
  }

  prefillForm() {
    if (document.getElementById("early-finish")?.value === "true") return;

    this.scoreTargets.forEach((target) => {
      if (target.dataset.player === this.firstFinisherTarget.value) {
        target.value = 0;
        target.style.color = "purple";
        target.style.fontWeight = "bold";
        target.readOnly = true;
      } else {
        target.value = "";
        target.style.color = "";
        target.style.fontWeight = "";
        target.readOnly = false;
      }
    });
  }

  editRound(event) {
    this.firstFinisherTarget.value = event.currentTarget.dataset.firstFinisher
    const row = event.currentTarget.closest('tr');

    this.scoreTargets.forEach(input => {
      const player = input.dataset.player;
      const cell = row.querySelector(`td[data-player='${player}']`);
      if (cell) {
        input.value = cell.textContent.trim();
      } else {
        input.value = "";
      }

      if (player === this.firstFinisherTarget.value) {
        input.style.color = "purple";
        input.style.fontWeight = "bold";
        input.readOnly = true;
      } else {
        input.style.color = "";
        input.style.fontWeight = "";
        input.readOnly = false;
      }
    });

    const roundId = event.currentTarget.dataset.roundId;
    const form = document.getElementById("score-form");
    form.action = `/rounds/${roundId}`;

    const modalTitle = document.querySelector("#my_modal_3 .modal-box h3");
    const roundNumber = event.currentTarget.dataset.round;
    if (modalTitle) {
      modalTitle.textContent = `Edit scores for round ${roundNumber}`;
    }

    my_modal_3.showModal()
  }

  checkButton() {
    const firstFinisherSelected = this.firstFinisherTarget.value !== "";
    const allScoresFilled = this.scoreTargets.every(input => input.value !== "" && input.value !== null);

    if (firstFinisherSelected && allScoresFilled) {
      this.saveButtonTarget.disabled = false;
    } else {
      this.saveButtonTarget.disabled = true;
    }
  }
}
