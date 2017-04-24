import {Socket} from "phoenix"

let connectSocket = function({userId, userToken, roomToken, roomId}) {
  let socket = new Socket("/socket", {params: {
    user_token: userToken
  }})

  socket.onError((err) => {
    $('.alert-danger').text("Disconnected from server")
  })

  socket.connect()

  console.log(`Connected to room: ${roomToken}`)

  // Chat

  let chatChannel = socket.channel(`chat:${roomId}`, {room_token: roomToken})

  let messageInput = $('.message-input')
  let chatContent = $('.rooms-chat-div')

  messageInput.keyup(function(e){
    if (e.keyCode == 13 && messageInput.val() != ""){
      e.preventDefault()
      chatChannel.push('message', messageInput.val())
      messageInput.val("")
    }
  })

  chatChannel.on('message', ({name, text}) => {
    let p = `<p><em>${sanitize(name)}</em>: ${sanitize(text)}`
    chatContent.prepend(p)
  })

  chatChannel.join()
    .receive("ok", resp => { console.log("Joined to chat successfully", resp) })
    .receive("error", resp => {
      console.log("Unable to join to chat", resp)
      $('.alert-danger').text(resp["message"])
    })

  function sanitize(text) {
    return $('<div/>').text(text).html()
  }

  // Game

  let roomChannel = socket.channel(`room:${roomId}`, {room_token: roomToken})

  let beginGameButton    = $('#begin_game')
  let rerollDiceButton   = $('#reroll_dice')
  let registerCombinationsButtons = $('.register_combination')

  beginGameButton.on('click', event => {
    roomChannel.push('begin_game')
  })

  let diceToReroll = function() {
    return [0, 1, 2, 3, 4].filter(i => {
      return $(`#die-${i}-input`).prop('checked')
    })
  }

  $("input[type=checkbox]").on('change', () => {
    if (diceToReroll().length > 0) {
      enableRerollDiceButton()
    } else {
      disableRerollDiceButton()
    }
  });

  rerollDiceButton.on('click', event => {
    let toReroll = diceToReroll()
    roomChannel.push('reroll_dice', toReroll)
  })

  registerCombinationsButtons.on('click', event => {
    roomChannel.push('register_combination', $(event.target).data('combination'))
  })

  roomChannel.on('room_state', payload => {
    console.log("Received game state: ")
    console.log(payload)

    renderGameState(payload)
  })

  roomChannel.on('error', ({message}) => {
    $('.alert-danger').text(message)
  })

  roomChannel.join()
    .receive("ok", resp => { console.log("Joined to room successfully", resp) })
    .receive("error", resp => {
      console.log("Unable to join to room", resp)
      $('.alert-danger').text(resp["message"])
      rerollDiceButton.hide()
      registerCombinationsButtons.hide()
      hideDice()
      beginGameButton.hide()
    })

  // Payload example: {
  //   game_started: ...
  //   game_over: ...
  //   current_player_id: ...
  //   players: [{
  //     id:
  //     name:
  //     game_state: {
  //       current_round: {
  //         throws_left:
  //         dice:
  //       },
  //       upper_bonus: 0,
  //       total: 0
  //       ones: ...
  //     }
  //   }]
  // }
  function renderGameState(payload) {
    renderPlayers(payload)

    if (payload['game_over']) {
      return renderGameOver(payload)
    }

    if (payload['game_started']) {
      return renderGameProgress(payload)
    }

    renderGamePending(payload)
  }

  function renderGameOver(payload) {
    rerollDiceButton.hide()
    beginGameButton.hide()
    registerCombinationsButtons.hide()
    hideDice()

    let player = winningPlayer(payload)

    highlightPlayerTotal(player['id'])
    highlightPlayer(null)

    $('.rooms-show-div').removeClass('col-xs-8')
    $('.rooms-show-div').addClass('col-xs-12')
  }

  function renderGamePending(_payload) {
    rerollDiceButton.hide()
    registerCombinationsButtons.hide()
    hideDice()
  }

  function renderGameProgress(payload) {
    beginGameButton.hide()

    let player = currentPlayer(payload)
    highlightPlayer(player.id)
    renderDice(player["game_state"]["current_round"]["dice"])

    if (myTurn(payload)) {
      return renderControlsForMyTurn(payload)
    }

    renderControlsForOtherPlayerTurn(payload)
  }

  function renderControlsForMyTurn(payload) {
    registerCombinationsButtons.show()

    let currentRound = currentPlayer(payload)['game_state']['current_round']

    if (currentRound['throws_left'] == 0) {
      disableDice()
      rerollDiceButton.hide()
    } else {
      enableDice()
      rerollDiceButton.show()
      disableRerollDiceButton()
    }
  }

  function renderControlsForOtherPlayerTurn(_payload) {
    rerollDiceButton.hide()
    disableDice()
    registerCombinationsButtons.hide()
  }

  function renderPlayers(payload) {
    payload.players.forEach((player) => {
      addPlayer(player)

      if (payload['game_started']) {
        let score = $(Object.keys(player['game_state']))
          .not(["current_round", "game_over"]).get()

        for (let key of score) {
          $(`.score-${key} .user_${player['id']}`).text(player['game_state'][key])
        }
      }
    })
  }

  function addPlayer(player) {
    let selector = `.score-player-names .user_${player['id']}`

    if ($(selector).length == 0) {
      let td = `<td class='player user_${player['id']}'></td>`
      let th = `<th class='player user_${player['id']}'></th>`

      $('th.player-first').after(th)
      $('td.player-first').after(td)

      $(selector).html(player['name'])
    }
  }

  function renderDice(dice) {
    resetDice()
    showDice()

    dice.forEach((face, i) => {
      $(`#die-${i}`).addClass(`die-face-${face}`)
    })
  }

  function resetDice() {
    for (let i of [1, 2, 3, 4, 5, 6]) {
      $('.die-face').removeClass(`die-face-${i}`)
    }

    for (let i of [0, 1, 2, 3, 4]) {
      $(`#die-${i}-input`).prop("checked", false)
    }
  }

  function hideDice() {
    $('.die-face').hide()
  }

  function showDice() {
    $('.die-face').show()
  }

  function disableDice() {
    $('.die-check input').attr('disabled', true)
  }

  function enableDice() {
    $('.die-check input').attr('disabled', false)
  }

  function myTurn(payload) {
    return payload['current_player_id'].toString() == userId
  }

  function winningPlayer(payload) {
    return payload['players'].reduce((acc, player) => {
      return player['game_state']['total'] > acc['game_state']['total'] ? player : acc
    })
  }

  function currentPlayer(payload) {
    let id = payload["current_player_id"]

    return $.grep(payload["players"], function(player) {
      return player['id'] == id
    })[0]
  }

  function disableRerollDiceButton() {
    rerollDiceButton.prop('disabled', true).addClass('disabled')
  }

  function enableRerollDiceButton() {
    rerollDiceButton.prop('disabled', false).removeClass('disabled')
  }

  function highlightPlayer(id) {
    $('.score-player-names .player').removeClass('text-success')

    if (id !== null) {
      $(`.score-player-names .user_${id}`).addClass('text-success')
    }
  }

  function highlightPlayerTotal(id) {
    $(`.score-total .user_${id}`).addClass('text-bold')
  }
}

export default connectSocket
