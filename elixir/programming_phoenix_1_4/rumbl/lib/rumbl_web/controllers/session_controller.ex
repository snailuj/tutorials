defmodule RumblWeb.SessionController do
  use RumblWeb, :controller

  def new(conn, _) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => %{"username" => username, "password" => password}}) do
    case Rumbl.Accounts.authenticate_by_username_and_password(username, password) do
      {:ok, user} ->
        conn
        |> RumblWeb.Auth.login(user)
        |> put_flash(:info, "Welcome") # TODO gettext me
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, _reason} -> # TODO log unsuccessful login
        conn
        |> put_flash(:error, "Invalid username/password combination")
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> RumblWeb.Auth.logout()
    |> put_flash(:info, "Logged out") # TODO gettext me
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
