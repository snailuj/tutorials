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

    # setup /session/login and /session/logout as routes
    # instead of /session/new and /session/delete
    get "/login", SessionController, :new
    get "/logout", SessionController, :delete

    resources "/rooms", RoomController
    resources "/users", UserController
    # normally resources will use all typical actions and will have e.g. /users/:id but we
    # don't want either of those for sessions
    resources "/sessions", SessionController, only: [:new, :create, :delete], singleton: true
  end

  # Other scopes may use custom stacks.
  # scope "/api", ChitChatWeb do
  #   pipe_through :api
  # end
end
