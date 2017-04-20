defmodule YahtzeePhoenix.ChatChannel do
  use YahtzeePhoenix.Web, :channel

  alias YahtzeePhoenix.User
  alias YahtzeePhoenix.Room

  def join("chat:" <> room_id, %{"room_token" => room_token}, socket) do
    user_id = socket.assigns.user_id
    case Repo.get_by(Room, token: room_token, id: room_id) do
      %Room{} ->
        {:ok, assign(socket, :user_name, Repo.get!(User, user_id).name)}
      _ -> {:error, %{message: "Unable to join"}}
    end
  end

  def handle_in("message", message, socket) when is_binary(message) do
    broadcast! socket, "message", %{name: socket.assigns.user_name, text: message}
    {:noreply, socket}
  end
end
