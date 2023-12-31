defmodule YahtzeePhoenix.RoomChannel do
  use YahtzeePhoenix.Web, :channel

  alias YahtzeePhoenix.User
  alias YahtzeePhoenix.Room

  def join("room:" <> room_id, %{"room_token" => room_token}, socket) do
    user_id = socket.assigns.user_id
    case Repo.get_by(Room, token: room_token, id: room_id) do
      %Room{state: room_state = %{"game_over" => true}} ->
        send self(), {:broadcast_game_results, room_state}
        {:ok, socket}
      %Room{} ->
        {:ok, room_pid} = Yahtzee.RoomSupervisor.spawn_or_find_room(room_id)
        {:ok, client_pid} = start_or_find_client(%{
          user_id: user_id,
          user_name: Repo.get!(User, user_id).name,
          room_pid: room_pid,
          room_id: room_id
        })
        send self(), :broadcast_room_state
        socket =
          socket
          |> assign(:client_pid, client_pid)
          |> assign(:room_pid, room_pid)
        {:ok, socket}
      _ -> {:error, %{message: "Unable to join"}}
    end
  end

  def handle_info(:broadcast_room_state, socket) do
    YahtzeePhoenix.Client.broadcast_room_state!(socket.assigns.client_pid)

    {:noreply, socket}
  end

  def handle_info({:broadcast_game_results, room_state}, socket) do
    push socket, "room_state", room_state

    {:stop, :normal, socket}
  end

  def handle_in("begin_game", _, socket) do
    try do
      Yahtzee.Servers.Room.begin_game!(socket.assigns.room_pid)
    rescue
      _ -> push socket, "error", %{message: "Error beginning the game"}
    end

    {:noreply, socket}
  end

  def handle_in("reroll_dice", [], socket) do
    push socket, "error", %{message: "Empty reroll is not possible"}

    {:noreply, socket}
  end
  def handle_in("reroll_dice", dice_to_reroll, socket) do
    case YahtzeePhoenix.Client.reroll_dice!(socket.assigns.client_pid, dice_to_reroll) do
      :ok -> nil
      {:error, message} -> push socket, "error", %{message: message}
    end

    {:noreply, socket}
  end

  def handle_in("register_combination", combination, socket) do
    case YahtzeePhoenix.Client.register_combination!(socket.assigns.client_pid, combination) do
      :ok -> nil
      {:error, message} -> push socket, "error", %{message: message}
    end

    {:noreply, socket}
  end

  def start_or_find_client(%{user_id: user_id, user_name: user_name, room_pid: room_pid, room_id: room_id}) do
    YahtzeePhoenix.ClientSupervisor.spawn_or_find_client(%{user_id: user_id, user_name: user_name, room_pid: room_pid, room_id: room_id})
  end
end
