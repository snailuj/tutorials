defmodule KV do
  @moduledoc """
  Application module
  """
  use Application

  def start(_type, _args) do
    KV.Supervisor.start_link(name: KV.Supervisor)
  end

  # can also define a `stop` function if needed
end
