defmodule YahtzeePhoenix.GameChannel do
  use YahtzeePhoenix.Web, :channel

  def join("game", %{}, socket) do
    {:ok, client_pid} = start_or_find_client(%{
      user_token: socket.assigns.user_token,
      user_id: socket.assigns.user_id
    })
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

  defp start_or_find_client(%{user_token: user_token, user_id: user_id}) do
    IO.puts "user_id: #{inspect(user_id)}"
    IO.puts "user_token: #{inspect(user_token)}"
    case find_client(user_id) do
      :undefined ->
        IO.puts "validating token"
        if YahtzeePhoenix.User.validate_token(user_id, user_token) do
          IO.puts "passed"
          Yahtzee.Servers.Room.spawn_client(YahtzeePhoenix.Client, %{
            user_token: user_token,
            user_id: user_id
          }, name: via_tuple(user_id))
        else
          IO.puts "failed"
          :error
        end
      pid ->
        IO.puts "found existing"
        {:ok, pid}
    end
  end

  defp via_tuple(user_id) do
    {:via, :gproc, {:n, :l, {:client, user_id}}}
  end

  defp find_client(user_id) do
    IO.puts "trying to find client for #{inspect(user_id)}"
    :gproc.where({:n, :l, {:client, user_id}})
  end
end
