// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix"

let connectSocket = function({userId, userToken, roomToken, roomId}) {
  let socket = new Socket("/socket", {params: {
    user_token: userToken,
    user_id: userId
  }})

  socket.connect()

  console.log("Connecting to room: " + roomToken)

  let channel = socket.channel("game:" + roomId, {room_token: roomToken})

  let beginGameButton    = $('#begin_game')
  let rerollDiceButton   = $('#reroll_dice')
  let registerCombinationsButtons = $('.register_combination')

  beginGameButton.on('click', event => {
    channel.push('begin_game')
  })

  rerollDiceButton.on('click', event => {
    let to_reroll = [0, 1, 2, 3, 4].filter(i => {
      return $('#die-' + i + '-input').prop("checked")
    })
    channel.push('reroll_dice', to_reroll)
  })

  registerCombinationsButtons.on('click', event => {
    channel.push('register_combination', $(event.target).data('combination'))
  })

  channel.on('game_state', payload => {
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
    payload.players.forEach((player) => {
      let selector = ".score-player-names .user_" + player['id'];

      if ($(selector).length == 0) {
        addPlayer(player)
        $(selector).html(player['name']);
      }

      if (payload['game_started']) {
        renderPlayerScore(player)
      }
    })

    let player = currentPlayer(payload)

    showControls(payload)

    if (payload['game_started']) {
      highlightPlayer(player.id)
      renderDice(player["game_state"]["current_round"]["dice"])
      beginGameButton.hide()
    } else {
      rerollDiceButton.hide()
      registerCombinationsButtons.hide()
      hideDice()
    }
  }

  function renderPlayerScore(player) {
    let score = $(Object.keys(player['game_state']))
      .not(["current_round", "game_over"]).get()

    for (let key of score) {
      $(".score-" + key + " .user_" + player['id']).text(player['game_state'][key])
    }
  }

  function renderDice(dice) {
    resetDice()
    showDice()

    dice.forEach((face, i) => {
      $("#die-" + i).addClass("die-face-" + face)
    })
  }

  function resetDice() {
    for (let i of [1, 2, 3, 4, 5, 6]) {
      $('.die-face').removeClass('die-face-' + i)
    }

    for (let i of [0, 1, 2, 3, 4]) {
      $('#die-' + i + '-input').prop("checked", false)
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

  function currentPlayer(payload) {
    let id = payload["current_player_id"]

    return $.grep(payload["players"], function(player) {
      return player['id'] == id
    })[0]
  }

  function showControls(payload) {
    if (payload['game_started'] && myTurn(payload)) {
      registerCombinationsButtons.show()

      let currentRound = currentPlayer(payload)['game_state']['current_round']

      if (currentRound['throws_left'] == 0) {
        disableDice()
        rerollDiceButton.hide()
      } else {
        enableDice()
        rerollDiceButton.show()
      }
    } else {
      rerollDiceButton.hide()
      disableDice()
      registerCombinationsButtons.hide()
    }
  }

  function addPlayer(player) {
    var td = "<td class='player user_" + player['id'] + "'></td>"
    var th = "<th class='player user_" + player['id'] + "'></th>"

    $('th.player:nth-child(2)').before(th)
    $('td.player:nth-child(2)').before(td)
  }

  function highlightPlayer(id) {
    $('.score-player-names .player').removeClass('text-primary')
    $('.score-player-names .user_' + id).addClass('text-primary')
  }
}

export default connectSocket
