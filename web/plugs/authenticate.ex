defmodule YahtzeePhoenix.Plugs.Authenticate do
  import Plug.Conn

  def init(_), do: []

  def call(conn, _) do
    if user_id = get_session(conn, :user_id) do
      user = YahtzeePhoenix.Repo.get(YahtzeePhoenix.User, user_id)
      assign(conn, :current_user, user)
    else
      conn
    end
  end
end
