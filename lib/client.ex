defmodule YahtzeePhoenix.Client do
  use GenServer

  alias YahtzeePhoenix.Repo
  alias YahtzeePhoenix.Room

  @combination_strings Enum.map(Yahtzee.Core.Combinations.symbols, &to_string/1)

  # Client API

  def start_link(%{user_id: user_id, user_name: user_name, room_pid: room_pid, room_id: room_id}, name) do
    GenServer.start_link(__MODULE__, %{user_id: user_id, user_name: user_name, room_pid: room_pid, room_id: room_id}, name: name)
  end

  def reroll_dice!(client_pid, dice_to_reroll) do
    GenServer.call(client_pid, {:reroll_dice, dice_to_reroll})
  end

  def register_combination!(client_pid, combination) do
    GenServer.call(client_pid, {:register_combination, combination})
  end

  def broadcast_room_state!(client_pid) do
    :ok = GenServer.cast(client_pid, :broadcast_room_state)
  end

  # Server API

  def init(%{user_id: user_id, user_name: user_name, room_pid: room_pid, room_id: room_id}) do
    player_pid = Yahtzee.Servers.Room.register_join!(room_pid, %{id: user_id, name: user_name})

    {:ok, %{player_pid: player_pid, room_pid: room_pid, room_id: room_id, user_id: user_id}}
  end

  # From Player

  def handle_cast({:ask_which_dice_to_reroll, _}, state) do
    broadcast_room_state!(self())
    new_state = Map.put(state, :in_reroll, true)
    {:noreply, new_state}
  end

  def handle_cast({:ask_combination, _}, state) do
    broadcast_room_state!(self())
    new_state = Map.put(state, :in_ask_combination, true)
    {:noreply, new_state}
  end

  def handle_cast({:game_over, room_state}, state = %{room_id: room_id}) do
    result = add_user_data_to_room_state(room_state)

    YahtzeePhoenix.Endpoint.broadcast! "room:" <> room_id, "room_state", result

    if this_process_is_first_player?(room_state) do
      winner_id =
        result[:players]
        |> Enum.max_by(fn(player) -> player[:game_state][:total] end)
        |> Map.fetch!(:id)

      Repo.update!(Room.game_over_changeset(Repo.get!(Room, room_id), winner_id, result))
    end

    {:stop, :normal, state}
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
      new_state =
        state
        |> Map.delete(:in_ask_combination)
        |> Map.delete(:in_reroll)
      {:reply, :ok, new_state}
    else
      {:reply, {:error, "Wrong time for register combination"}, state}
    end
  end

  def handle_cast(:broadcast_room_state, state = %{room_pid: room_pid, room_id: room_id}) do
    result = add_user_data_to_room_state(Yahtzee.Servers.Room.full_state(room_pid))

    YahtzeePhoenix.Endpoint.broadcast! "room:" <> room_id, "room_state", result

    {:noreply, state}
  end

  defp can_register_combination?(state) do
    state[:in_reroll] || state[:in_ask_combination]
  end

  defp add_user_data_to_room_state(%{players: players, game_started: game_started, game_over: game_over, current_player_number: current_player_number}) do
    players =
      players
      |> Enum.map(fn(player) -> player[:user] |> Map.put(:game_state, player[:game_state]) end)

    result = %{
      game_started: game_started,
      game_over: game_over,
      players: players,
    }

    if game_started && !game_over do
      Map.put(result, :current_player_id, Enum.at(players, current_player_number)[:id])
    else
      result
    end
  end

  defp this_process_is_first_player?(%{players: [%{client_pid: first_client_pid} | _]}) when first_client_pid == self(), do: true
  defp this_process_is_first_player?(_), do: false
end
