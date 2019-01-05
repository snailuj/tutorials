defmodule ChitChatWeb.SessionController do
  # brings in all the functionality of Phoenix controllers
  # `use ChitChatWeb, :controller` is shorthand for `use ChitChatWeb, controller: true`
  use ChitChatWeb, :controller

  # Alias this because we're going to be using it a lot
  alias ChitChat.Accounts

  def new(conn, _) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    # 3 cases either get back a valid user or it'll be unauthorised, or it'll be not found
    case Accounts.authenticate_by_email_password(email, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> put_session(:user_id, user.id)
        # opposite of drop: true
        |> configure_session(renew: true)
        |> redirect(to: "/")

      {:error, :unauthorized} ->
        conn
        |> put_flash(:error, "Bad email/password combination")
        |> redirect(to: Routes.session_path(conn, :new))

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Account not found")
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end

  def delete(conn, _) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:success, "Successfully signed out")
    |> redirect(to: "/")
  end
end
