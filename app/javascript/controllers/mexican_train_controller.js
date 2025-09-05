import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["firstFinisher", "score", "saveButton", "scoreCell"]
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
    this.resetScoreForm();
    this.firstFinisherTarget.value = event.currentTarget.dataset.firstFinisher || "";
    const roundNumber = event.currentTarget.dataset.round;
    const roundId = event.currentTarget.dataset.roundId;

    const scoreCells = this.scoreCellTargets.filter(cell => cell.dataset.round === roundNumber);

    const endButton = document.getElementById("end-round-btn");

    // Only prefill scores if NOT clicking the end round button
    if (event.currentTarget !== endButton) {
      this.scoreTargets.forEach(input => {
        const player = input.dataset.player;
        const cell = scoreCells.find(cell => cell.dataset.player === player);

        if (cell) {
          let scoreText = cell.textContent.trim();
          if (scoreText === "-") {
            input.value = "";
          } else {
            input.value = scoreText;
          }
        } else {
          input.value = "";
        }

        if (player === this.firstFinisherTarget.value) {
          input.style.color = "purple";
          input.style.fontWeight = "bold";
          if (document.getElementById("early-finish")?.value === "false") {
            input.readOnly = true;
          }
        } else {
          input.style.color = "";
          input.style.fontWeight = "";
          input.readOnly = false;
        }
      });
    } else {
      // For end round, just reset styles (already done by resetScoreForm)
      this.scoreTargets.forEach(input => {
        if (input.dataset.player === this.firstFinisherTarget.value) {
          input.style.color = "purple";
          input.style.fontWeight = "bold";
          if (document.getElementById("early-finish")?.value === "false") {
            input.readOnly = true;
          }
        } else {
          input.style.color = "";
          input.style.fontWeight = "";
          input.readOnly = false;
        }
      });
    }


    const form = document.getElementById("score-form");
    if (roundId) {
      form.action = `/rounds/${roundId}`;
      console.log(form.action)
    }

    const modalTitle = document.querySelector("#my_modal_3 .modal-box h3");
    if (event.currentTarget === endButton) {
      modalTitle.textContent = `Enter scores for round ${endButton.dataset.roundNumber}`;
    } else {
      modalTitle.textContent = `Edit scores for round ${roundNumber}`;
    }

    my_modal_3.showModal();
  }

  resetScoreForm() {
    // Reset all score inputs and styles
    this.scoreTargets.forEach(input => {
      input.value = "";
      input.style.color = "";
      input.style.fontWeight = "";
      input.readOnly = false;
    });
    if (this.hasFirstFinisherTarget) {
      this.firstFinisherTarget.value = "";
    }
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

  confirmEndGame(event) {
    event.preventDefault()
    Swal.fire({
      title: "Go the the results page ?",
      text: "You won't be able to revert this!",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#3085d6",
      cancelButtonColor: "#d33",
      confirmButtonText: "Finish the game!"
    }).then((result) => {
      if (result.isConfirmed) {
        document.getElementById("finish-game-form").submit();
      }
    });
  }
}
