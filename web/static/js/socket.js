// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {
  user_token: sessionStorage.getItem('user_token'),
  user_id: sessionStorage.getItem('user_id')
}})

socket.connect()

let channel = socket.channel("game", {})

let begin_game_button    = $('#begin_game')
let reroll_dice_button   = $('#reroll_dice')
let register_combination = $('.register_combination')

begin_game_button.on('click', event => {
  channel.push('begin_game')
})

reroll_dice_button.on('click', event => {
  let to_reroll = [0, 1, 2, 3, 4].filter(i => {
    return $('#die-' + i + '-input').prop("checked")
  })
  channel.push('reroll_dice', to_reroll)
})

register_combination.on('click', event => {
  channel.push('register_combination', $(event.target).data('combination'))
})

channel.on('game_state', payload => {
  console.log(payload)

  if(payload['game_started']) {
    begin_game_button.hide()
    renderGameState(payload)
  } else {
    reroll_dice_button.hide()
    register_combination.hide()
  }
})

channel.on('error', ({message}) => {
  $('.alert-danger').text(message)
})

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket

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
    if ($(".score-" + key + " .user_" + player_id).length == 0) {
      addPlayer(player)
    }

    renderPlayerScore(player)
  })

  showControls(payload)

  renderDice(currentPlayer()["current_round"]["dice"])
}

function renderPlayerScore(player) {
  let score = $(Object.keys(player['game_state']))
    .not(["user_id", "current_round"]).get()

  for (let key of score) {
    $(".score-" + key + " .user_" + player['id']).text(score[key])
  }
}

function renderDice(dice) {
  resetDice()

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

function myTurn(payload) {
  return payload["current_player_id"].toString() == sessionStorage.getItem('user_id')
}

function currentPlayer(payload) {
  let id = payload["current_player_id"]

  return $.grep(payload["players"], function(player) {
    return player['id'] == id
  })
}

function showControls(payload) {
  if (myTurn(payload)) {
    register_combination.show()

    if (payload['current_round']['throws_left'] == 0) {
      reroll_dice_button.hide()
    } else {
      reroll_dice_button.show()
    }
  } else {
    reroll_dice_button.hide()
    register_combination.hide()
  }
}

function addPlayer(player) {
  var td = "<td class='player user_" + player['id'] + "'>" + player['name'] + "</td>"

  $('.player').after(td)
}

window.addPlayer = addPlayer
