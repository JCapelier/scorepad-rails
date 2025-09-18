import DefaultScoresheetController from "controllers/default_scoresheet_controller"

export default class extends DefaultScoresheetController {

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
    const roundNumber = event.currentTarget.dataset.roundNumber;
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
    }

    const modalTitle = document.querySelector("#my_modal_3 .modal-box h3");
    if (event.currentTarget === endButton) {
      modalTitle.textContent = `Enter scores for round ${endButton.dataset.roundNumber}`;
    } else {
      modalTitle.textContent = `Edit scores for round ${roundNumber}`;
    }

    my_modal_3.showModal();
  }
}
