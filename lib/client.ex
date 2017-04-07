defmodule YahtzeePhoenix.Client do
  use GenServer

  @combination_strings Enum.map(Yahtzee.Core.Combinations.symbols, &to_string/1)

  # Client API

  def start_link(%{user_id: user_id, user_name: user_name}, name) do
    GenServer.start_link(__MODULE__, %{user_id: user_id, user_name: user_name}, name: name)
  end

  def reroll_dice!(client_pid, dice_to_reroll) do
    :ok = GenServer.cast(client_pid, {:reroll_dice, dice_to_reroll})
  end

  def register_combination!(client_pid, combination) do
    :ok = GenServer.cast(client_pid, {:register_combination, combination})
  end

  def broadcast_game_state(client_pid) do
    :ok = GenServer.cast(client_pid, :broadcast_game_state)
  end

  # Server API

  def init(%{user_id: user_id, user_name: user_name}) do
    player_pid = Yahtzee.Servers.Room.register_join!

    {:ok, %{player_pid: player_pid, user_id: user_id, user_name: user_name}}
  end

  def handle_cast(:broadcast_game_state, state = %{player_pid: player_pid}) do
    broadcast_game_state(Yahtzee.Core.Player.game_state(player_pid), state)
    {:noreply, state}
  end

  # From Player

  def handle_cast({:ask_which_dice_to_reroll, game_state}, state) do
    broadcast_game_state(game_state, state)
    new_state = Map.put(state, :in_reroll, true)
    {:noreply, new_state}
  end

  def handle_cast({:ask_combination, game_state}, state) do
    broadcast_game_state(game_state, state)
    new_state = Map.put(state, :in_ask_combination, true)
    {:noreply, new_state}
  end

  # From Channel

  def handle_cast({:reroll_dice, dice_to_reroll}, state = %{player_pid: player_pid, in_reroll: true}) do
    Yahtzee.Core.Player.next_roll! player_pid, dice_to_reroll
    new_state = Map.delete(state, :in_reroll)
    {:noreply, new_state}
  end
  def handle_cast({:reroll_dice, _}, state) do
    broadcast_error(state, "Wrong moment for reroll")
    {:noreply, state}
  end

  def handle_cast({:register_combination, combination}, state = %{player_pid: player_pid}) do
    if Enum.member?(@combination_strings, combination) && can_register_combination?(state) do
      try do
        Yahtzee.Core.Player.register_combination! player_pid, String.to_atom(combination)
        handle_cast(:broadcast_game_state, state)
      rescue
        _ -> broadcast_error(state, "Wrong time for register combination")
      end
    else
      broadcast_error(state, "Wrong time for register combination")
    end
    new_state =
      state
      |> Map.delete(:in_ask_combination)
      |> Map.delete(:in_reroll)
    {:noreply, new_state}
  end

  defp broadcast_error(state, message) do
    YahtzeePhoenix.Endpoint.broadcast "game", "error", add_user_data(%{message: message}, state)
  end

  defp broadcast_game_state(game_state, state) do
    YahtzeePhoenix.Endpoint.broadcast "game", "game_state", add_user_data(game_state, state)
  end

  defp add_user_data(game_state, state) do
    Map.merge game_state, %{
      user_id: state[:user_id],
      user_name: state[:user_name]
    }
  end

  defp can_register_combination?(state) do
    state[:in_reroll] || state[:in_ask_combination]
  end
end
