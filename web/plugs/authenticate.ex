defmodule YahtzeePhoenix.Plugs.Authenticate do
  import Plug.Conn

  def init(_), do: []

  def call(conn, _) do
    if user_id = get_session(conn, :user_id) do
      conn
      |> assign(:current_user, YahtzeePhoenix.Repo.get(YahtzeePhoenix.User, user_id))
      |> assign(:current_user_token, Phoenix.Token.sign(conn, "user", user_id))
    else
      conn
    end
  end
end
