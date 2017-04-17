defmodule YahtzeePhoenix.RoomController do
  use YahtzeePhoenix.Web, :controller

  alias YahtzeePhoenix.Room

  def index(conn, _params) do
    finished_rooms =
      Room
      |> Room.finished
      |> Room.with_winner
      |> Repo.all

    open_rooms =
      Room
      |> Room.open
      |> Room.with_winner
      |> Repo.all

    render(conn, "index.html", finished_rooms: finished_rooms, open_rooms: open_rooms)
  end

  def create(conn, _params) do
    changeset = Room.create_changeset

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
        conn
        |> render("show.html", room: room)
    end
  end
end
