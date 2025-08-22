import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["input", "results", "selected", "submit", "sortableList", "guestInput"]
  connect() {
    this.defaultAvatarUrl = this.element.dataset.defaultAvatarUrl || "/assets/default-avatar.jpg"
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

  addGuest() {
    const name = this.guestInputTarget.value.trim()
    if (!name) return
    const guest = {
      guest_name: name,
      guest_id: `guest_${Date.now()}`,
      avatar_url: this.defaultAvatarUrl
    }
    this.selectedPlayers.push(guest)
    this.guestInputTarget.value = ""
    this.displaySelected()
    this.checkButton()
  }

  displaySelected() {
    this.selectedTarget.innerHTML = ""
    this.selectedPlayers.forEach((player, index) => {
      const card = document.createElement("div")
      card.className = "relative flex flex-col items-center bg-gray-100 rounded-lg p-3 m-2 shadow-sm w-24"
      let name, avatar, hiddenFields
      if (player.user_id || player.id) {
        // Real user
        name = player.username
        avatar = player.avatar_url
        hiddenFields = `
          <input type="hidden" name="game_session[session_players_attributes][${index}][user_id]" value="${player.id}">
          <input type="hidden" name="game_session[session_players_attributes][${index}][position]" value="${index + 1}">
        `
      } else {
        // Guest
        name = player.guest_name
        avatar = player.avatar_url || "/default-avatar.jpg"
        hiddenFields = `
          <input type="hidden" name="game_session[session_players_attributes][${index}][guest_id]" value="${player.guest_id}">
          <input type="hidden" name="game_session[session_players_attributes][${index}][guest_name]" value="${player.guest_name}">
          <input type="hidden" name="game_session[session_players_attributes][${index}][position]" value="${index + 1}">
        `
      }
      card.innerHTML = `
        <button type="button" class="absolute top-1 right-1 text-gray-400 hover:text-red-500 font-bold" title="Remove">&times;</button>
        <img src="${avatar}" alt="avatar" class="w-12 h-12 rounded-full mb-2">
        <span class="text-xs font-medium text-gray-800 text-center truncate w-full">${name}</span>
        ${hiddenFields}
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
    console.log(min)
    const max = parseInt(this.submitTarget.dataset.maxPlayers, 10)
    console.log(max)
    const count = this.selectedPlayers.length
    console.log(count)
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
      let name = player.username || player.guest_name
      let avatar = player.avatar_url || "/default-avatar.jpg"
      li.innerHTML = `
        <img src="${avatar}" alt="avatar" class="w-8 h-8 rounded-full mr-3">
        <span class="font-medium text-gray-800 text-base truncate flex-1">${name}</span>
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
          const aName = a.username || a.guest_name
          const bName = b.username || b.guest_name
          return newOrder.indexOf(aName) - newOrder.indexOf(bName)
        })
        this.displaySelected()
        this.createList()
      }
    })
  }
}
