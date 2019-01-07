defmodule ChitChat.Auth do
  # Writing this as a Plug instead of a Controller. You could arguably do it either way
  # but often you end up with many Plugs and many Controllers in an application, so it
  # makes sense to split them out like this

  import Plug.Conn
  # Need to import Controller for `put_flash/3` and `redirect`
  import Phoenix.Controller
  alias ChitChatWeb.Router.Helpers
  alias ChitChatWeb.ErrorView

  # To be a valid Plug, we need two things:
  #   a `call` function, that gets run every time the Plug is used
  #   an `init` function, where you put the more expensive work

  # placeholder
  # if we had a more complex Plug, we could use this `init` function
  # to transform the options, which will then get passed through to
  # `call` everytime it's called
  def init(opts), do: opts

  # Each `Plug.call/2` method receives a `Plug.Conn` and returns a
  # `Plug.Conn`. So the `call` sites define a pipeline that gradually
  # transforms the `Plug.Conn` into its final form
  # @spec call(Plug.Conn.t(), any()) :: Plug.Conn
  def call(conn, _opts) do
    # `get_session` is something available because we imported `Plug.Conn`
    user_id = get_session(conn, :user_id)
    user = user_id && ChitChat.Accounts.get_user!(user_id)

    put_current_user(conn, user)

    # Now we have the current user, or `false` if not logged in, anywhere in the app
  end

  # Restrict access to a page depending whether a user is logged in or not
  # This function head matches on if the conn assigns have a current_user set to an actual struct
  # Just return the exact same conn -- absolutely no effect if user is logged in
  def logged_in_user(conn = %{assigns: %{current_user: %ChitChat.Accounts.User{}}}, _), do: conn

  # Didn't match the function head above, so they must not be logged in
  def logged_in_user(conn, _) do
    conn
    |> put_flash(:error, "You must be logged in to access that page")
    |> redirect(to: Helpers.page_path(conn, :index))
    # if you don't halt after a redirect then the Conn will get rendered twice and that causes probs
    |> halt()
  end

  def admin_user(conn = %{asigns: %{admin_user: true}}, _), do: conn

  def admin_user(conn, opts) do
    if opts[:pokerface] do
      conn
      |> put_status(404)
      |> render(ErrorView, :"404", message: "Page not found")
      |> halt()
    end

    conn
    |> put_flash(:error, "You do not have access to that page")
    |> redirect(to: Helpers.page_path(conn, :index))
    # if you don't halt after a redirect then the Conn will get rendered twice and that causes probs
    |> halt()
  end

  def put_current_user(conn, user) do
    conn
    # Put the current User into the assigns
    |> assign(:current_user, user)
    |> assign(
      :admin_user,
      # obviously in a real app you'd want to use roles for this!
      !!user && !!user.credential && !!(user.credential.email == "julian.suggate@gmail.com")
    )
  end
end
