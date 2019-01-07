defmodule NounProjex do
  import OAuther

  @moduledoc """
  [Noun Project](https://thenounproject.com) API Client in Elixir
  """

  @doc """
  Returns a single collection by id (int)
  """
  def get_collection(id) do
    key = "REPLACE_ME"
    secret = "REPLACE_ME"
    method = "get"
    url = "http://api.thenounproject.com/collection/#{id}"

    credentials = OAuther.credentials(consumer_key: key, consumer_secret: secret)
    auth_params = OAuther.sign(method, url, [], credentials)

    {header, _req_params} = OAuther.header(auth_params)

    {:ok, _code, _headers, ref} = :hackney.request(:get, url, [header])
    {:ok, body} = :hackney.body(ref)
    Jason.decode(body)
  end
end
