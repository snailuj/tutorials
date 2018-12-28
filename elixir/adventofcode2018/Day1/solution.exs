defmodule Day1 do
  def read_input() do
    for(
      s <- File.read!("input.txt") |> String.split("\n", trim: true),
      do: String.to_integer(s)
    )
  end

  def part1() do
    read_input()
    |> Enum.sum()
  end

  def part2(f, init, map) when length(f) == 0 do
    read_input()
    |> part2(init, map)
  end

  def part2([head | tail], step, map) do
    cond do
      not MapSet.member?(map, step + head) ->
        part2(tail, step + head, MapSet.put(map, step + head))

      true ->
        IO.puts("duplicate #{Integer.to_string(step + head)}")
    end
  end
end

IO.puts(Day1.part1())
IO.puts(Day1.part2([], 0, MapSet.new()))
