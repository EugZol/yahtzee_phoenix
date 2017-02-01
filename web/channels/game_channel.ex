defmodule YahtzeePhoenix.GameChannel do
  use YahtzeePhoenix.Web, :channel

  def join("game", %{name: name}, socket) do
    {:ok, socket}
  end
end
