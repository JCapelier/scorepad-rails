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
        target.style.color = "purple";
        target.style.fontWeight = "bold";
      } else {
        target.style.color = "";
        target.style.fontWeight = "";
      }
    });
  }

  editRound(event) {
    this.resetScoreForm();
    this.firstFinisherTarget.value = event.currentTarget.dataset.firstFinisher || "";
    const roundNumber = event.currentTarget.dataset.roundNumber;
    const roundId = event.currentTarget.dataset.roundId;

    const scoreCells = this.scoreCellTargets.filter(cell => cell.dataset.roundNumber === roundNumber);

    this.scoreTargets.forEach(input => {
      const player = input.dataset.player;
      const cell = scoreCells.find(cell => cell.dataset.player === player);

      if (cell) {
                console.log("coucou")
                console.log(cell)
                console.log(cell.dataset)
        console.log(cell.dataset.childMode)
        let scoreText = cell.textContent.trim();
        if (scoreText === "-") {
          console.log("salut")
          input.value = "";
        } else if (cell.dataset.finishStatus === "failure" && cell.dataset.player === this.firstFinisherTarget.value && cell.dataset.childMode === "false") {
          input.value = parseInt(scoreText, 10) / 2;
        } else {
          console.log("bonjour")
          input.value = scoreText;
        }
      } else {
        input.value = "";
      }

      if (player === this.firstFinisherTarget.value) {
        input.style.color = "purple";
        input.style.fontWeight = "bold";
      } else {
        input.style.color = "";
        input.style.fontWeight = "";
      }
    });

    const form = document.getElementById("score-form");
    const endButton = document.getElementById("end-round-btn")
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
