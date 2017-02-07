defmodule YahtzeePhoenix.Client do
  use GenServer

  @combination_strings Enum.map(Yahtzee.Core.Combinations.symbols, &to_string/1)

  # Client API

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  def reroll_dice!(client_pid, dice_to_reroll) do
    :ok = GenServer.cast(client_pid, {:reroll_dice, dice_to_reroll})
  end

  def register_combination!(client_pid, combination) do
    :ok = GenServer.cast(client_pid, {:register_combination, combination})
  end

  # Server API

  def init(%{user_token: user_token, user_id: user_id}) do
    player_pid = Yahtzee.Servers.Room.register_join!

    {:ok, %{player_pid: player_pid, user_token: user_token, user_id: user_id}}
  end

  def handle_cast({:ask_which_dice_to_reroll, game_state}, state) do
    YahtzeePhoenix.Endpoint.broadcast "game", "game_state", add_user_data(game_state, state)
    {:noreply, state}
  end

  def handle_cast({:ask_combination, game_state}, state) do
    YahtzeePhoenix.Endpoint.broadcast "game", "game_state", add_user_data(game_state, state)
    {:noreply, state}
  end

  def handle_cast({:reroll_dice, dice_to_reroll}, state = %{player_pid: player_pid}) do
    Yahtzee.Core.Player.next_roll! player_pid, dice_to_reroll
    {:noreply, state}
  end

  def handle_cast({:register_combination, combination}, state = %{player_pid: player_pid}) do
    if Enum.member?(@combination_strings, combination) do
      Yahtzee.Core.Player.register_combination! player_pid, String.to_atom(combination)
    end
    {:noreply, state}
  end

  defp add_user_data(game_state, state) do
    Map.merge game_state, %{
      user_id: state[:user_id]
    }
  end
end
