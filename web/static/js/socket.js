// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix"

function rand() {
  return Math.random().toString(36).substr(2)
}

if (!sessionStorage.getItem('user_id')) {
  sessionStorage.setItem('user_id', rand())
}
if (!sessionStorage.getItem('user_token')) {
  sessionStorage.setItem('user_token', rand())
}

let socket = new Socket("/socket", {params: {
  user_token: sessionStorage.getItem('user_token'),
  user_id: sessionStorage.getItem('user_id')
}})
socket.connect()

let channel = socket.channel("game", {})

let begin_game_button    = $('#begin_game')
let reroll_dice_button   = $('#reroll_dice')
let register_combination = $('#register_combination')

begin_game_button.on('click', event => {
  channel.push('begin_game')
})

reroll_dice_button.on('click', event => {
  channel.push('reroll_dice', [1])
})

register_combination.on('click', event => {
  channel.push('register_combination', 'ones')
})

channel.on('game_state', payload => {
  $('#score').html(JSON.stringify(payload))
})

channel.on('game_started', (_) => {
  $('#score').html("Game started")
})

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
