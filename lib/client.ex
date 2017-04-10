defmodule YahtzeePhoenix.Client do
  use GenServer

  @combination_strings Enum.map(Yahtzee.Core.Combinations.symbols, &to_string/1)

  # Client API

  def start_link(%{user_id: user_id, user_name: user_name}, name) do
    GenServer.start_link(__MODULE__, %{user_id: user_id, user_name: user_name}, name: name)
  end

  def reroll_dice!(client_pid, dice_to_reroll) do
    GenServer.call(client_pid, {:reroll_dice, dice_to_reroll})
  end

  def register_combination!(client_pid, combination) do
    GenServer.call(client_pid, {:register_combination, combination})
  end

  def user_data(client_pid) do
    GenServer.call(client_pid, :user_data)
  end

  def broadcast_game_state(room_pid, self_state \\ nil) do
    %{
      player_pids: player_pids,
      current_player_number: current_player_number,
      game_started: game_started
    } = Yahtzee.Servers.Room.state(room_pid)

    game_states =
      player_pids
      |> Enum.map(fn(player_pid) -> Yahtzee.Core.Player.game_state(player_pid) end)

    IO.puts "player_pids: #{inspect(player_pids)}"
    IO.puts "game_states: #{inspect(game_states)}"

    extract_user_data_from_client = fn(client_pid) ->
      if self() == client_pid do
        %{id: self_state[:user_id], name: self_state[:user_name]}
      else
        user_data(client_pid)
      end
    end

    players =
      player_pids
      |> Enum.map(fn(player_pid) -> Yahtzee.Core.Player.client_pid(player_pid) end)
      |> Enum.map(extract_user_data_from_client)
      |> Enum.zip(game_states)
      |> Enum.map(fn {user_data, game_state} -> Map.put(user_data, :game_state, game_state) end)

    result =
      if game_started do
        %{
          game_started: game_started,
          players: players,
          current_player_id: Enum.at(players, current_player_number - 1)[:id]
        }
      else
        %{
          game_started: game_started,
          players: players
        }
      end

    IO.puts "Sending game_state: #{inspect(result)}"

    YahtzeePhoenix.Endpoint.broadcast! "game", "game_state", result

    result
  end

  # Server API

  def init(%{user_id: user_id, user_name: user_name}) do
    player_pid = Yahtzee.Servers.Room.register_join!

    {:ok, %{player_pid: player_pid, user_id: user_id, user_name: user_name}}
  end

  def handle_call(:game_state, _, state = %{player_pid: player_pid}) do
    game_state = Yahtzee.Core.Player.game_state(player_pid)
    {:reply, game_state, state}
  end

  def handle_call(:user_data, _, state = %{user_id: user_id, user_name: user_name}) do
    {:reply, %{id: user_id, name: user_name}, state}
  end

  # From Player

  def handle_cast({:ask_which_dice_to_reroll, _game_state}, state) do
    broadcast_game_state(Yahtzee.Servers.Room, state)
    new_state = Map.put(state, :in_reroll, true)
    {:noreply, new_state}
  end

  def handle_cast({:ask_combination, _game_state}, state) do
    broadcast_game_state(Yahtzee.Servers.Room, state)
    new_state = Map.put(state, :in_ask_combination, true)
    {:noreply, new_state}
  end

  # From Channel

  def handle_call({:reroll_dice, dice_to_reroll}, _, state = %{player_pid: player_pid, in_reroll: true}) do
    Yahtzee.Core.Player.next_roll! player_pid, dice_to_reroll
    new_state = Map.delete(state, :in_reroll)
    {:reply, :ok, new_state}
  end
  def handle_call({:reroll_dice, _}, _, state) do
    {:reply, {:error, "Wrong moment for reroll"}, state}
  end

  def handle_call({:register_combination, combination}, _, state = %{player_pid: player_pid}) do
    if Enum.member?(@combination_strings, combination) && can_register_combination?(state) do
      Yahtzee.Core.Player.register_combination! player_pid, String.to_atom(combination)
      broadcast_game_state(Yahtzee.Servers.Room, state)
      new_state =
        state
        |> Map.delete(:in_ask_combination)
        |> Map.delete(:in_reroll)
      {:reply, :ok, new_state}
    else
      {:reply, {:error, "Wrong time for register combination"}, state}
    end
  end

  defp can_register_combination?(state) do
    state[:in_reroll] || state[:in_ask_combination]
  end
end
