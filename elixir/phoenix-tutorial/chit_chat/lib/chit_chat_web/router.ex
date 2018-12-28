defmodule ChitChatWeb.Router do
  use ChitChatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ChitChatWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/rooms", RoomController
    resources "/users", UserController
  end

  # Other scopes may use custom stacks.
  # scope "/api", ChitChatWeb do
  #   pipe_through :api
  # end
end
