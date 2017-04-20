// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix"

let connectSocket = function({userId, userToken, roomToken, roomId}) {
  let socket = new Socket("/socket", {params: {
    user_token: userToken
  }})

  socket.onError((err) => {
    $('.alert-danger').text("Disconnected from server")
  })

  socket.connect()

  console.log(`Connecting to room: ${roomToken}`)

  let channel = socket.channel(`room:${roomId}`, {room_token: roomToken})

  let beginGameButton    = $('#begin_game')
  let rerollDiceButton   = $('#reroll_dice')
  let registerCombinationsButtons = $('.register_combination')

  beginGameButton.on('click', event => {
    channel.push('begin_game')
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
    channel.push('reroll_dice', toReroll)
  })

  registerCombinationsButtons.on('click', event => {
    channel.push('register_combination', $(event.target).data('combination'))
  })

  channel.on('room_state', payload => {
    console.log("Received game state: ")
    console.log(payload)

    renderGameState(payload)
  })

  channel.on('error', ({message}) => {
    $('.alert-danger').text(message)
  })

  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

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

  function renderGamePending(payload) {
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
      var td = `<td class='player user_${player['id']}'></td>`
      var th = `<th class='player user_${player['id']}'></th>`

      $('th.player:nth-child(2)').before(th)
      $('td.player:nth-child(2)').before(td)

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
