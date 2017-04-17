defmodule YahtzeePhoenix.Plugs.EnsureResourceBelongsToCurrentUser do
  import Plug.Conn
  import Phoenix.Controller

  def init(extract_user_id_from_conn), do: extract_user_id_from_conn

  def call(conn, extract_user_id_from_conn) do
    if conn.assigns.current_user && (Integer.to_string(conn.assigns.current_user.id) == extract_user_id_from_conn.(conn)) do
      conn
    else
      conn
      |> put_status(:not_found)
      |> render(YahtzeePhoenix.ErrorView, "404.html")
      |> halt
    end
  end
end
