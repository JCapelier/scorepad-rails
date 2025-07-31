import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["input", "results", "selected", "submit", "sortableList"]
  connect() {
    console.log("Coucou")
    this.selectedPlayers=[]
    this.checkButton()
  }

  search(event) {
    const input = event.currentTarget.value
    if (input.length < 2) return

    fetch(`/users/autocomplete?input=${encodeURIComponent(input)}`)
      .then(response => response.json())
      .then(users => {
        this.displayResults(users)
      })
  }

  displayResults(users) {
    this.resultsTarget.innerHTML = ""
    users.forEach(user => {
      if (this.selectedPlayers.find(player => player.username === user.username)) return

      const card = document.createElement("div")
      card.className = "flex flex-col items-center bg-gray-100 rounded-lg p-3 m-2 shadow-sm w-24 cursor-pointer"
      card.innerHTML = `
        <img src=${user.avatar_url} alt="avatar" class="w-12 h-12 rounded-full mb-2">
        <span class="text-xs font-medium text-gray-800 text-center truncate w-full">${user.username}</span>
      `
      card.addEventListener("click", () => {
        this.addPlayer(user)
      })
      this.resultsTarget.appendChild(card)
    })
  }

  addPlayer(player) {
    this.selectedPlayers.push(player)
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
    this.displaySelected()
    this.checkButton()
  }

  displaySelected() {
    this.selectedTarget.innerHTML = ""
    this.selectedPlayers.forEach((player, index) => {
      const card = document.createElement("div")
      card.className = "relative flex flex-col items-center bg-gray-100 rounded-lg p-3 m-2 shadow-sm w-24"
      card.innerHTML = `
        <button type="button" class="absolute top-1 right-1 text-gray-400 hover:text-red-500 font-bold" title="Remove">&times;</button>
        <img src=${player.avatar_url} alt="avatar" class="w-12 h-12 rounded-full mb-2">
        <span class="text-xs font-medium text-gray-800 text-center truncate w-full">${player.username}</span>
        <input type="hidden" name="game_session[session_players_attributes][${index}][user_id]" value="${player.id}">
        <input type="hidden" name="game_session[session_players_attributes][${index}][position]" value="${index + 1}">
      `
      card.querySelector("button").addEventListener("mousedown", () => {
        this.selectedPlayers.splice(index, 1)
        this.displaySelected()
        this.checkButton()
      })
      this.selectedTarget.appendChild(card)
    })
  }

  checkButton() {
    const min = parseInt(this.submitTarget.dataset.minPlayers, 10)
    const max = parseInt(this.submitTarget.dataset.maxPlayers, 10)
    const count = this.selectedPlayers.length
    this.submitTarget.disabled = (count < min || count > max)
  }

  createList() {
    const container = document.createElement("div")
    container.className = "flex flex-row gap-2"

    const labelsCol = document.createElement("div")
    labelsCol.className = "flex flex-col items-start mr-2 justify-around"
    this.selectedPlayers.forEach((_, index) => {
      let posLabel = `${index + 1}`
      if (index === 0) posLabel = "1st"
      else if (index === 1) posLabel = "2nd"
      else if (index === 2) posLabel = "3rd"
      else posLabel = `${index + 1}th`
      const label = document.createElement("span")
      label.className = "w-10 text-lg font-bold text-purple-700 text-left"
      label.textContent = posLabel
      labelsCol.appendChild(label)
    })

    const ol = document.createElement("ol")
    ol.className = "w-full"
    this.selectedPlayers.forEach((player) => {
      const li = document.createElement("li")
      li.className = "flex items-center bg-gray-100 rounded-lg px-3 py-2 m-1 shadow-sm mb-2"
      li.innerHTML = `
        <img src="${player.avatar_url}" alt="avatar" class="w-8 h-8 rounded-full mr-3">
        <span class="font-medium text-gray-800 text-base truncate flex-1">${player.username}</span>
      `
      ol.appendChild(li)
    })

    container.appendChild(labelsCol)
    container.appendChild(ol)

    this.sortableListTarget.innerHTML = ""
    this.sortableListTarget.appendChild(container)

    Sortable.create(ol, {
      animation: 150,
      onEnd: (evt) => {
        const newOrder = Array.from(ol.children).map(li => li.querySelector("span").textContent)
        this.selectedPlayers.sort((a, b) => {
          return newOrder.indexOf(a.username) - newOrder.indexOf(b.username)
        })
        this.displaySelected()
        this.createList()
      }
    })
  }
}
