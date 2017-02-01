defmodule YahtzeePhoenix.PageController do
  use YahtzeePhoenix.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
