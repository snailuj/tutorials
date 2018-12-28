defmodule Adventmix do
  def read_input(day) do
    #path is relative to mix.exs file
    File.read!("input/day" <> day <> ".txt")
    |> String.split("\n", trim: true)
  end
end
