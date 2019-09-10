defmodule PhatWeb.ChatLiveView do
  use Phoenix.LiveView
  alias Phat.Chats
  alias PhatWeb.Presence

  defp get_topic(chat_id), do: "chat:#{chat_id}"

  def render(assigns) do
    PhatWeb.ChatView.render("show.html", assigns)
  end

  def mount(%{chat: chat, current_user: current_user}, socket) do
    # When this LiveView process mounts, we want to add them to Presence tracking:
    # we use self() to track the presence of each individual ChatLiveView process
    # along with a payload describing the new user, under a topic of "chat:#{chat.id}"
    # keyed by User ID.
    # When a user navigates away from the chat page, their LiveView process terminates.
    # This triggers a call to `Presence.untrack/3` with that PID, meaning that the
    # Presence behaviour will send a new "presence_diff" event to all subscribers. TL;DR,
    # we get the Leave events for free
    Presence.track_presence(self(), get_topic(chat.id), current_user.id, %{
      first_name: current_user.first_name,
      email: current_user.email,
      user_id: current_user.id,
      typing: false
    })

    get_topic(chat.id) |> PhatWeb.Endpoint.subscribe()

    {:ok,
     assign(socket,
       chat: chat,
       message: Chats.change_message(),
       current_user: current_user,
       users: get_topic(chat.id) |> Presence.list_presences()
     )}
  end

  @doc """
    Handles the new chat message event from client
  """
  def handle_event("message", %{"message" => params}, socket) do
    chat = Chats.create_message(params)

    # broadcast_from broadcasts to all subscribers excluding self
    PhatWeb.Endpoint.broadcast_from(self(), get_topic(chat.id), "message", %{chat: chat})
    {:noreply, assign(socket, chat: chat, message: Chats.change_message())}
  end

  @doc """
    Called when a user is typing
  """
  def handle_event("typing", _value, socket = %{assigns: %{chat: chat, current_user: user}}) do
    Presence.update_presence(self(), get_topic(chat.id), user.id, %{typing: true})
    {:noreply, socket}
  end

  @doc """
    Called when a user blurs the message input
  """
  def handle_event(
        "stop_typing",
        value,
        socket = %{assigns: %{chat: chat, current_user: user, message: message}}
      ) do
    message = Chats.change_message(message, %{content: value})
    Presence.update_presence(self(), get_topic(chat.id), user.id, %{typing: false})

    # calling `Presence.update_presence` triggers "presence_diff", which triggers a
    # re-render, so we need to stash the user's message in the state so it doesn't get wiped
    {:noreply, assign(socket, message: message)}
  end

  @doc """
    Handles the new chat message broadcast from PubSub channel
  """
  def handle_info(%{event: "message", payload: state}, socket) do
    {:noreply, assign(socket, state)}
  end

  @doc """
    Handles presence changes in the chatroom
  """
  def handle_info(%{event: "presence_diff"}, socket = %{assigns: %{chat: chat}}) do
    # 1. get the list of present users
    # `Presence.list` returns a map with shape:
    #   %{
    #     "1" => %{
    #       metas: [
    #         %{
    #           email: "sophie@email.com",
    #           first_name: "Sophie",
    #           phx_ref: "TNV4PzRfyhw="
    #           user_id: 1
    #         }
    #       ]
    #     },
    #     "2" => %{
    #       metas: [
    #         %{
    #           email: "beini@email.com",
    #           first_name: "Beini",
    #           phx_ref: "ZZ30QuoI/8s="
    #           user_id: 1
    #         }
    #       ]
    #     }
    #     ...
    # }
    #
    # where the keys of that map are the User ID
    #

    users =
      get_topic(chat.id)
      |> Presence.list_presences()

    # 2. update the liveview socket state with new list
    {:noreply, assign(socket, users: users)}
  end
end
