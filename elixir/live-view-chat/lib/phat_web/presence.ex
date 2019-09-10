defmodule PhatWeb.Presence do
  use Phoenix.Presence,
    otp_app: :phat, # where the configuration is found, would be the umbrella for umbrella projects
    pubsub_server: Phat.PubSub

  alias PhatWeb.Presence

  def track_presence(pid, topic, key, payload) do
    Presence.track(pid, topic, key, payload)
  end

  def update_presence(pid, topic, key, payload) do
    metas =
      # get the metadata in this topic for the given key
      Presence.get_by_key(topic, key)[:metas]
      # we only store one meta per key so use first
      |> List.first()
      # and just merge it with the given payload
      |> Map.merge(payload)

    Presence.update(pid, topic, key, metas)
  end

  def list_presences(topic) do
    Presence.list(topic)
    |> Enum.map(fn {_user_id, data} ->
      data[:metas]
      |> List.first()
    end)
  end
end
