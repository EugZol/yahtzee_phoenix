defmodule YahtzeePhoenix.GameChannel do
  use YahtzeePhoenix.Web, :channel

  def join("game", %{}, socket) do
    {:ok, client_pid} = YahtzeePhoenix.Client.start_link(%{
      user_token: socket.assigns.user_token,
      user_id: socket.assigns.user_id
    })
    {:ok, assign(socket, :client_pid, client_pid)}
  end

  def handle_in("begin_game", _, socket) do
    Yahtzee.Servers.Room.begin_game!
    broadcast! socket, "game_started", %{}
    {:noreply, socket}
  end

  def handle_in("reroll_dice", dice_to_reroll, socket) do
    YahtzeePhoenix.Client.reroll_dice!(socket.assigns.client_pid, dice_to_reroll)
    {:noreply, socket}
  end

  def handle_in("register_combination", combination, socket) do
    YahtzeePhoenix.Client.register_combination!(socket.assigns.client_pid, combination)
    {:noreply, socket}
  end
end
