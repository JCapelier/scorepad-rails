import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scoreCell", "bidCell", "bid", "tricks", "saveButton"]
  connect() {
    this.checkButton();

    // For bidding modal
    if (this.hasBidTarget) {
      this.bidTargets.forEach(input => {
        input.addEventListener('change', () => this.checkButton());
      });
    }
    // For scoring modal
    if (this.hasTricksTarget) {
      this.tricksTargets.forEach(input => {
        input.addEventListener('change', () => this.checkButton());
      });
    }
  }
  closeModalAfterSuccess(event) {
    window.my_modal_3.close()
  }

  checkButton() {
    // Only check the visible form
    const biddingForm = document.getElementById("bidding-score-form");
    const scoringForm = document.getElementById("scoring-score-form");
    let form = null;
    let values = [];
    let phase = null;
    let cardsPerRound = 0;
    let saveButton = null;

    if (biddingForm && biddingForm.offsetParent !== null) {
      form = biddingForm;
      phase = "bidding";
      values = this.bidTargets.map(input => input.value);
      saveButton = biddingForm.querySelector('[data-oh-hell-target="saveButton"]');
      cardsPerRound = parseInt(form.dataset.numberOfCards, 10);
    } else if (scoringForm && scoringForm.offsetParent !== null) {
      form = scoringForm;
      phase = "scoring";
      values = this.tricksTargets.map(input => input.value);
      saveButton = scoringForm.querySelector('[data-oh-hell-target="saveButton"]');
      cardsPerRound = parseInt(form.dataset.numberOfCards, 10);
    }
    if (!form || !saveButton) return;

    const allFilled = values.every(val => val !== "" && val !== null);
    // Only sum if all are filled, otherwise sum is NaN and disables button
    let sum = 0;
    if (allFilled) {
      sum = values.reduce((acc, val) => acc + Number(val), 0);
    }
    const allValid = values.every(val => val !== "" && val !== null && !isNaN(Number(val)) && Number(val) <= cardsPerRound && Number(val) >= 0);
    let enable = false;
    if (phase === "bidding") {
      enable = allFilled && allValid && Number(sum) !== Number(cardsPerRound);
    } else if (phase === "scoring") {
      enable = allFilled && allValid && Number(sum) === Number(cardsPerRound);
    }
    saveButton.disabled = !enable;
  }

  resetScoreForm() {
    // Reset all score inputs and styles
    if (this.hasBidTarget) {
      this.bidTargets.forEach(input => { input.value = ""; });
    }
    if (this.hasTricksTarget) {
      this.tricksTargets.forEach(input => { input.value = ""; });
    }}

  editRound(event) {
    const phase = event.currentTarget.dataset.roundPhase;
    const status = event.currentTarget.dataset.roundStatus;
    if (phase === "bidding" && (status === "pending" || status === "active")) {
      this.editBidding(event);
    } else {
      // For completed rounds, pass the event and a flag to editScoring
      this.editScoring(event, true);
    }
  }

  editBidding(event) {
    // Show bidding form, hide scoring form
    document.getElementById("bidding-form").style.display = "block";
    document.getElementById("scoring-form").style.display = "none";

    // Set each bid select to the previously chosen value for the current round
    const roundNumber = event.currentTarget.dataset.roundNumber || event.currentTarget.dataset.round;
    // For each bid select, set value from data-bid attribute if present
    this.bidTargets.forEach(input => {
      const bid = input.dataset.bid;
      if (bid !== undefined && bid !== null && bid !== "") {
        input.value = bid;
      }
    });

    // Set modal title
    const modalTitle = document.querySelector("#my_modal_3 .modal-box h3");
    modalTitle.textContent = `Enter bids for round ${roundNumber}`;

    my_modal_3.showModal();
  }

  editScoring(event, isCompletedRound = false) {
    // Show scoring form, hide bidding form
    document.getElementById("scoring-form").style.display = "block";
    document.getElementById("bidding-form").style.display = "none";

    const scoringForm = document.getElementById("scoring-score-form");
    const roundNumber = event.currentTarget.dataset.roundNumber || event.currentTarget.dataset.round;
    const roundId = event.currentTarget.dataset.roundId;

    if (isCompletedRound) {
      // Get number of cards for this round from the row's data attribute, or fallback to 0
      let cardsPerRound = 0;
      if (event.currentTarget.dataset.cardsPerRound) {
        cardsPerRound = parseInt(event.currentTarget.dataset.cardsPerRound, 10);
      } else {
        // fallback: try to get from a bid cell
        const bidCell = event.currentTarget.querySelector('[data-oh-hell-target="bid-cell"]');
        if (bidCell) {
          cardsPerRound = parseInt(bidCell.getAttribute('data-cards-per-round'), 10) || 0;
        }
      }
      // Update form's data-number_of_cards
      if (scoringForm) {
        scoringForm.dataset.numberOfCards = cardsPerRound;
        scoringForm.action = `/rounds/${roundId}`;
      }

      // For each tricks select, update options and value
      this.tricksTargets.forEach(input => {
        const player = input.dataset.player;
        // Set options
        input.innerHTML = "";
        for (let i = 0; i <= cardsPerRound; i++) {
          const option = document.createElement('option');
          option.value = i;
          option.textContent = i;
          input.appendChild(option);
        }
        // Set value from data-score-<username>
        const score = event.currentTarget.getAttribute(`data-score-${player}`);
        if (score !== undefined && score !== null && score !== "") {
          input.value = score;
        }
      });

      // Update the "Bid" display for each player
      this.tricksTargets.forEach(input => {
        const player = input.dataset.player;
        const bid = event.currentTarget.getAttribute(`data-bid-${player}`);
        // Find the bid display span (assumes structure: span.w-20 inside the same parent)
        const parent = input.closest('.form-control');
        if (parent) {
          const bidSpan = parent.querySelector('span.w-20');
          if (bidSpan) {
            bidSpan.textContent = `Bid: ${bid ?? ''}`;
          }
        }
      });
    } else {
      // Optionally reset form fields if needed
      this.resetScoreForm();
    }

    // Set modal title
    const modalTitle = document.querySelector("#my_modal_3 .modal-box h3");
    modalTitle.textContent = `Enter scores for round ${roundNumber}`;

    my_modal_3.showModal();
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
