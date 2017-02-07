defmodule YahtzeePhoenix.SessionController do
  use YahtzeePhoenix.Web, :controller

  alias YahtzeePhoenix.User

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => session_params}) do
    case User.login(session_params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Session created successfully.")
        |> redirect(to: "/")
      :error ->
        conn
        |> put_flash(:error, "Please check your email or password")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session
    |> put_flash(:info, "Session deleted successfully.")
    |> redirect(to: "/")
  end
end
