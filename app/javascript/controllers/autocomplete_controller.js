import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// This needs to be reworked. The autocomplete actually takes care of everything in the new game session view...

export default class extends Controller {
  static targets = ["input", "results", "selected", "submit", "sortableList", "guestInput", "addGuestBtn", "guestNameMsg"]
  connect() {
    this.defaultAvatarUrl = this.element.dataset.defaultAvatarUrl || "/assets/default-avatar.jpg"
    // Get current user info from a data attribute
    const currentUser = {
      id: parseInt(this.element.dataset.currentUserId, 10),
      username: this.element.dataset.currentUsername,
      avatar_url: this.element.dataset.currentUserAvatarUrl
    }
    this.currentUser = currentUser
    this.selectedPlayers = [currentUser]
  this.displaySelected()
  this.checkButton()
    if (this.hasGuestInputTarget) {
      this.guestInputTarget.addEventListener("input", this.validateGuestName.bind(this))
    }
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
    let displayed = 0;
    users.forEach(user => {
      if (this.selectedPlayers.find(player => player.username === user.username)) return

      // Use same color logic as in displaySelected
      let isGuest = !(user.user_id || user.id)
      let cardBg = isGuest ? "bg-yellow-200" : "bg-purple-700"
      let textColor = isGuest ? "text-purple-800" : "text-yellow-200"

      const card = document.createElement("div")
      card.className = `flex flex-col items-center ${cardBg} rounded-lg p-3 m-2 shadow-sm w-24 cursor-pointer ${textColor}`
      card.innerHTML = `
        <img src=${user.avatar_url} alt="avatar" class="w-12 h-12 object-cover rounded-full mb-2">
        <span class="text-xs font-medium text-center truncate w-full">${user.username}</span>
      `
      card.addEventListener("click", () => {
        this.addPlayer(user)
      })
      this.resultsTarget.appendChild(card)
      displayed++;
    });
    if (displayed === 0) {
      const msg = document.createElement("div")
      msg.className = "text-sm text-gray-500 p-2 w-full text-center"
      msg.textContent = "No players go by this username."
      this.resultsTarget.appendChild(msg)
    }
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
    if (!name || name.includes(" ")) {
      this.showGuestNameMsg()
      return
    }
    const guest = {
      guest_name: name,
      guest_id: `guest_${Date.now()}`,
      avatar_url: this.defaultAvatarUrl
    }
    this.selectedPlayers.push(guest)
    this.guestInputTarget.value = ""
    this.displaySelected()
    this.checkButton()
    this.hideGuestNameMsg()
  }

  validateGuestName() {
    const name = this.guestInputTarget.value
    if (name.includes(" ")) {
      if (this.hasAddGuestBtnTarget) this.addGuestBtnTarget.disabled = true
      this.showGuestNameMsg()
    } else {
      if (this.hasAddGuestBtnTarget) this.addGuestBtnTarget.disabled = false
      this.hideGuestNameMsg()
    }
  }

  showGuestNameMsg() {
    if (this.hasGuestNameMsgTarget) {
      this.guestNameMsgTarget.textContent = "Guest's name cannot contain spaces."
      this.guestNameMsgTarget.style.display = "block"
    }
  }

  hideGuestNameMsg() {
    if (this.hasGuestNameMsgTarget) {
      this.guestNameMsgTarget.textContent = ""
      this.guestNameMsgTarget.style.display = "none"
    }
  }

  displaySelected() {
    this.selectedTarget.innerHTML = ""
    this.selectedPlayers.forEach((player, index) => {
      let isGuest = !(player.user_id || player.id)
      let isCurrentUser = player.id === this.currentUser.id
      let cardBg = isGuest ? "bg-yellow-200" : "bg-purple-700"
      let textColor = isGuest ? "text-purple-800" : "text-yellow-200"

      const card = document.createElement("div")
      card.className = `relative flex flex-col items-center ${cardBg} rounded-lg p-3 m-2 shadow-sm w-24 ${textColor}`
      let name, avatar, hiddenFields
      if (!isGuest) {
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
        avatar = null // No avatar for guest, show "Guest" in a circle instead
        hiddenFields = `
          <input type="hidden" name="game_session[session_players_attributes][${index}][guest_id]" value="${player.guest_id}">
          <input type="hidden" name="game_session[session_players_attributes][${index}][guest_name]" value="${player.guest_name}">
          <input type="hidden" name="game_session[session_players_attributes][${index}][position]" value="${index + 1}">
        `
      }
      card.innerHTML = `
        ${!isCurrentUser ? `<button type="button" class="absolute top-1 right-1 text-gray-400 hover:text-red-500 font-bold" title="Remove">&times;</button>` : ""}
        ${
          !isGuest
            ? `<img src="${avatar}" alt="avatar" class="w-12 h-12 object-cover rounded-full mb-2">`
            : `<div class="w-12 h-12 rounded-full border mb-2 bg-yellow-200 flex items-center justify-center text-purple-800 text-xs"><span>Guest</span></div>`
        }
        <span class="text-xs font-medium text-center truncate w-full">${name}</span>
        ${hiddenFields}
      `
      if (!isCurrentUser) {
        card.querySelector("button").addEventListener("mousedown", () => {
          this.selectedPlayers.splice(index, 1)
          this.displaySelected()
          this.checkButton()
        })
      }
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
      let isGuest = !(player.user_id || player.id)
      let cardBg = isGuest ? "bg-yellow-200" : "bg-purple-700"
      let textColor = isGuest ? "text-purple-800" : "text-yellow-200"

      const li = document.createElement("li")
      li.className = `flex items-center ${cardBg} rounded-lg px-3 py-2 m-1 shadow-sm mb-2 ${textColor}`
      let name = player.username || player.guest_name
      // For guests, show the guest circle; for users, show avatar
      let avatarHtml = isGuest
        ? `<div class="w-12 h-12 rounded-full border mb-2 bg-yellow-200 flex items-center justify-center text-purple-800 text-xs"><span>Guest</span></div>`
        : `<img src="${player.avatar_url || "/default-avatar.jpg"}" alt="avatar" class="w-12 h-12 object-cover rounded-full mb-2">`
      li.innerHTML = `
        ${avatarHtml}
        <span class="font-medium text-base truncate flex-1">${name}</span>
      `
      ol.appendChild(li)
    })

    container.appendChild(labelsCol)
    container.appendChild(ol)

    this.sortableListTarget.innerHTML = ""
    this.sortableListTarget.appendChild(container)

    Sortable.create(ol, {
      animation: 150,
      onStart: (evt) => {
        // Create a transparent image to avoid ghost trail
        const img = document.createElement("img");
        img.src = "data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=";
        img.style.position = "absolute";
        img.style.left = "-9999px";
        document.body.appendChild(img);
        evt.item.dragImgEl = img; // keep reference to remove later
        evt.originalEvent.dataTransfer.setDragImage(img, 0, 0);
      },
      onEnd: (evt) => {
        // Remove the transparent image after drag
        if (evt.item.dragImgEl) {
          document.body.removeChild(evt.item.dragImgEl);
          evt.item.dragImgEl = null;
        }
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
