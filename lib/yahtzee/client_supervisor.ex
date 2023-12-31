defmodule YahtzeePhoenix.ClientSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    supervise([worker(YahtzeePhoenix.Client, [], restart: :transient)], strategy: :simple_one_for_one)
  end

  def spawn_or_find_client(%{user_id: user_id, user_name: user_name, room_pid: room_pid, room_id: room_id}) do
    case find_client(room_pid, user_id) do
      :undefined ->
        Supervisor.start_child(__MODULE__, [%{user_id: user_id, user_name: user_name, room_pid: room_pid, room_id: room_id}, via_tuple(room_pid, user_id)])
      pid -> {:ok, pid}
    end
  end

  defp via_tuple(room_pid, user_id) do
    {:via, :gproc, {:n, :l, [client: user_id, room: room_pid]}}
  end

  defp find_client(room_pid, user_id) do
    :gproc.where({:n, :l, [client: user_id, room: room_pid]})
  end
end
