import DefaultScoresheetController from "controllers/default_scoresheet_controller"

export default class extends DefaultScoresheetController {
  static targets = ["bids", "bidCell", "scoreCell", "tricks", "saveBidsButton", "saveTricksButton", "bidReminder", "bidsInput", "tricksInput"]
  connect() {
  }
  closeModalAfterSuccess() {
    window.my_modal_3.close()
    window.my_modal_4.close()
  }

  checkBidsButton(event) {
    const bids = this.bidsInputTargets.map(bid => bid.value)
    const form = document.querySelector("#bidding-form")
    const numberOfCards = parseInt(form.dataset.cardsPerRound, 10)

    const allFilled = bids.every(bid => bid !== "" && bid !== null)
    let sum = 0
    if (allFilled) {
      sum = bids.reduce((accumulator, bid) => accumulator + Number(bid), 0)
    }

    if (allFilled && sum !== numberOfCards) {
      this.saveBidsButtonTarget.disabled = false
    } else {
      this.saveBidsButtonTarget.disabled = true }
  }

  checkTricksButton(event) {
    const tricks = this.tricksInputTargets.map(trick => trick.value)
    const form = document.querySelector("#scoring-form")
    const numberOfCards = parseInt(form.dataset.cardsPerRound, 10)
    const allFilled = tricks.every(trick => trick !== "" && trick !== null)
    let sum = 0
    if (allFilled) {
      sum = tricks.reduce((accumulator, trick) => accumulator + Number(trick), 0)
    }

    if (allFilled && sum === numberOfCards) {
      this.saveTricksButtonTarget.disabled = false
    } else {
      this.saveTricksButtonTarget.disabled = true }
  }

  resetForm() {
    if (this.hasBidsInputTarget) {
      this.bidsInputTargets.forEach(bid => { bid.value = ""; });
    }
    if (this.hasTricksInputTarget) {
      this.tricksInputTargets.forEach(trick => { trick.value = ""; });
    }}


  // editBidding and editScoring are nowhere near DRY enough...
  editBidding(event) {
    this.resetForm()
    this.checkBidsButton()
    const roundNumber = event.currentTarget.dataset.roundNumber
    const roundId = event.currentTarget.dataset.roundId
    const cardsPerRound = event.currentTarget.dataset.cardsPerRound
    const roundPath = `/rounds/${roundId}`
    const form = document.getElementById('bidding-form');
    form.action = roundPath;
    form.dataset.cardsPerRound = cardsPerRound;

    this.bidsInputTargets.forEach(target => {
      const bid = target.dataset.bid;
      if (bid !== undefined && bid !== null && bid !== "") {
        target.value = bid;
        // This snippet set the right number of options for the select, depending on the round
        for (let i = 0; i <= Number(cardsPerRound); i++) {
        const option = document.createElement("option");
        option.value = i;
        option.textContent = i;
        target.appendChild(option);
        target.value = ""
      }
      }
    });

    this.bidsInputTargets.forEach(input => {
      const previousCell = this.scoreCellTargets.find(target => target.dataset.player === input.dataset.player && target.dataset.roundId === roundId)
      if (previousCell && previousCell.dataset.bids !== undefined) {input.value = previousCell.dataset.bids}
    })

    this.checkBidsButton()

    const modalTitle = document.querySelector("#bidding-modal-title")
    modalTitle.textContent = `Enter bids for round ${roundNumber}`

    my_modal_3.showModal();
  }

  editScoring(event) {
    this.resetForm
    this.checkTricksButton(event)
    const roundId = event.currentTarget.dataset.roundId;
    const cardsPerRound = event.currentTarget.dataset.cardsPerRound;
    const roundPath = `/rounds/${roundId}`

    const form = document.getElementById('scoring-form');
    form.action = roundPath;
    form.dataset.cardsPerRound = cardsPerRound;

    this.tricksInputTargets.forEach(target => {
      target.innerHTML = "";
      for (let i = 0; i <= Number(cardsPerRound); i++) {
        const option = document.createElement("option");
        option.value = i;
        option.textContent = i;
        target.appendChild(option);
        target.value = ""
      }
    });


      this.tricksInputTargets.forEach(input => {
        const previousCell = this.scoreCellTargets.find(target => target.dataset.player === input.dataset.player && target.dataset.roundId === roundId)
        const playerBidReminder = this.bidReminderTargets.find(reminder => reminder.dataset.player === input.dataset.player)
        playerBidReminder.innerText = `Bid: ${previousCell.dataset.bids}`
        if (event.currentTarget.dataset.currentRound !== "true") {input.value = previousCell.dataset.tricks}
      })

    this.checkTricksButton(event)

    document.getElementById("scoring-modal-title").textContent = `Enter tricks for round ${event.currentTarget.dataset.roundNumber}`;

    my_modal_4.showModal();
  }

}
