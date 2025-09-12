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

  resetScoreForm() {
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

  // Edit round should be refactorize (at least for Skyjo, Mexican Train and Five Crowns)
  // Most of the logic is similar.

}
