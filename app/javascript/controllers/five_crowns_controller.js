import DefaultScoresheetController from "controllers/default_scoresheet_controller"

export default class extends DefaultScoresheetController {

  prefillForm() {
    const earlyFinish = this.element.dataset.earlyFinish;
    this.scoreTargets.forEach((target) => {
      if (target.dataset.player === this.firstFinisherTarget.value) {
        target.style.color = "purple";
        target.style.fontWeight = "bold";
        if (earlyFinish === "false") {
          target.value = 0;
          target.readOnly = true;
        } else {
          target.readOnly = false;
        }
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

    const scoreCells = this.scoreCellTargets.filter(cell => cell.dataset.roundNumber === roundNumber);

    const earlyFinish = this.element.dataset.earlyFinish;
    this.scoreTargets.forEach(input => {
      const player = input.dataset.player;
      const cell = scoreCells.find(cell => cell.dataset.player === player);

      if (cell) {
        let scoreText = cell.textContent.trim();
        if (scoreText === "-") {
          input.value = "";
        } else if (cell.dataset.finishStatus === "failure" && cell.dataset.player === this.firstFinisherTarget.value) {
          input.value = parseInt(scoreText, 10) / 2;
        } else {
          input.value = scoreText;
        }
      } else {
        input.value = "";
      }

      if (player === this.firstFinisherTarget.value) {
        input.style.color = "purple";
        input.style.fontWeight = "bold";
        if (earlyFinish === "false") {
          input.readOnly = true;
        } else {
          input.readOnly = false;
        }
      } else {
        input.style.color = "";
        input.style.fontWeight = "";
        input.readOnly = false;
      }
    });

    const form = document.getElementById("score-form");
    const endButton = document.getElementById("end-round-btn")
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
