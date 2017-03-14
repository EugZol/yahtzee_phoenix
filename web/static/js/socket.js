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
  let to_reroll = [1, 2, 3, 4, 5].filter(i => {
    return $('#die-' + i + '-input').prop("checked")
  })
  channel.push('reroll_dice', to_reroll)
})

register_combination.on('click', event => {
  channel.push('register_combination', $(event.target).data('combination'))
})

// Payload example: {
//   "user_id":"6",
//   "upper_bonus":0,
//   "total":0,
//   "current_round":{
//     "throws_left":2,
//     "dice":[5,6,3,3,5]
//   }
// }
channel.on('game_state', payload => {
  console.log(payload)

  let score = $(Object.keys(payload)).not(["user_id", "current_round"]).get()
  for (let key of score) {
    $("#" + key + "> td.user_" + payload["user_id"]).text(payload[key])
  }

  resetDice()

  payload["current_round"]["dice"].forEach((face, i) => {
    $("#die-" + (i + 1)).addClass("die-face-" + face)
  })
})

channel.on('error', ({message}) => {
  $('.alert-danger').text(message)
})

// channel.on('game_started', (payload) => {
//   for (let key in payload) {
//     console.log(key)
//     $("#" + key).text(payload[key])
//   }
// })

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket

function resetDice() {
  for (let i of [1, 2, 3, 4, 5, 6]) {
    $('.die-face').removeClass('die-face-' + i)
    $('#die-' + i + '-input').prop("checked", false)
  }
}
