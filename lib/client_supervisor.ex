defmodule YahtzeePhoenix.ClientSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    supervise([worker(YahtzeePhoenix.Client, [])], strategy: :simple_one_for_one)
  end

  def spawn_or_find_client(user_id) do
    case find_client(user_id) do
      :undefined ->
        Supervisor.start_child(__MODULE__, [user_id, via_tuple(user_id)])
      pid -> {:ok, pid}
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
