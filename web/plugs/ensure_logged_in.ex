defmodule YahtzeePhoenix.Plugs.EnsureLoggedIn do
  import Plug.Conn
  import Phoenix.Controller
  import YahtzeePhoenix.Router.Helpers

  def init(_), do: []

  def call(conn, _) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> redirect(to: session_path(conn, :new))
      |> halt
    end
  end
end
