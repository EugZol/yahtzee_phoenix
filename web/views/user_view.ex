defmodule YahtzeePhoenix.UserView do
  use YahtzeePhoenix.Web, :view

  alias YahtzeePhoenix.User
  alias YahtzeePhoenix.Repo

  def user_score(user) do
    user
    |> User.score
    |> Repo.one
  end

  def this_is_current_user?(conn) do
    Integer.to_string(conn.assigns.current_user.id) == conn.params["id"]
  end
end
