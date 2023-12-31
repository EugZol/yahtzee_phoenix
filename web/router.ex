defmodule YahtzeePhoenix.Router do
  use YahtzeePhoenix.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug YahtzeePhoenix.Plugs.Authenticate
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", YahtzeePhoenix do
    pipe_through :browser # Use the default browser stack

    get "/", RoomController, :index
    resources "/rooms", RoomController, only: [:show, :create]
    resources "/users", UserController
    resources "/session", SessionController, singleton: true, only: [:new, :create, :delete]
  end
end
