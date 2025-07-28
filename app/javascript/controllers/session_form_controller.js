import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const minPlayers = document.querySelector("#my_modal_2").dataset.minPlayers
    const maxPlayers = document.querySelector("#my_modal_2").dataset.maxPlayers
    console.log(`${minPlayers} ${maxPlayers}`)
  }

  addPlayer
}
