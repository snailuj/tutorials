defmodule KV do
  def start_link do
    Task.start_link(fn -> loop(%{}) end)
  end

  defp loop(map) do
    receive do
      {:get, key, caller} ->
        send caller, Map.get(map, key)
        map
        |> loop()
      {:put, key, value} ->
        map
        |> Map.put(key, value)
        |> loop()
    end
  end
end
