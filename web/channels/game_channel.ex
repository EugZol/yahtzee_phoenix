defmodule YahtzeePhoenix.GameChannel do
  use YahtzeePhoenix.Web, :channel

  alias YahtzeePhoenix.User

  def join("game", %{}, socket) do
    user_id = socket.assigns.user_id
    {:ok, client_pid} = start_or_find_client(%{
      user_token: socket.assigns.user_token,
      user_id: user_id,
      user_name: Repo.get!(User, user_id).name
    })
    YahtzeePhoenix.Client.broadcast_game_state(client_pid)
    {:ok, assign(socket, :client_pid, client_pid)}
  end

  def handle_in("begin_game", _, socket) do
    try do
      Yahtzee.Servers.Room.begin_game!
    rescue
      _ -> broadcast! socket, "error", %{message: "Error beginning the game"}
    else
      _ -> broadcast! socket, "game_started", %{}
    end
    {:noreply, socket}
  end

  def handle_in("reroll_dice", [], socket) do
    broadcast! socket, "error", %{message: "Empty reroll is not possible"}
    {:noreply, socket}
  end
  def handle_in("reroll_dice", dice_to_reroll, socket) do
    try do
      YahtzeePhoenix.Client.reroll_dice!(socket.assigns.client_pid, dice_to_reroll)
    rescue
      _ -> broadcast! socket, "error", %{message: "Error rerolling the dice"}
    end
    {:noreply, socket}
  end

  def handle_in("register_combination", combination, socket) do
    try do
      YahtzeePhoenix.Client.register_combination!(socket.assigns.client_pid, combination)
    rescue
      _ -> broadcast! socket, "error", %{message: "Error registering the combination"}
    end
    {:noreply, socket}
  end

  def start_or_find_client(%{user_token: user_token, user_id: user_id, user_name: user_name}) do
    if YahtzeePhoenix.User.validate_token(user_id, user_token) do
      YahtzeePhoenix.ClientSupervisor.spawn_or_find_client(%{user_id: user_id, user_name: user_name})
    else
      :error
    end
  end
end
