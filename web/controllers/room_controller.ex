defmodule YahtzeePhoenix.RoomController do
  use YahtzeePhoenix.Web, :controller

  alias YahtzeePhoenix.Room

  def index(conn, _params) do
    rooms = Repo.all(Room)
    render(conn, "index.html", rooms: rooms)
  end

  def create(conn, _params) do
    changeset = Room.create

    case Repo.insert(changeset) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "Room created successfully.")
        |> redirect(to: room_path(conn, :show, room))
    end
  end

  def show(conn, %{"id" => token}) do
    case Repo.get_by(Room, token: token) do
      nil ->
        conn
        |> put_flash(:error, "Room not found")
        |> redirect(to: room_path(conn, :index))
      room = %Room{} ->
        render(conn, "show.html", room: room)
    end
  end
end
