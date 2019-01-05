defmodule ChitChatWeb.PageController do
  use ChitChatWeb, :controller

  def index(conn, _params) do
    # get_session is avail on any Phoenix controller
    user_id = get_session(conn, :user_id)
    render(conn, "index.html", user_id: user_id)
  end
end
