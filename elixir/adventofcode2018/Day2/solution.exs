defmodule Day2 do
  defp read_input() do
    for(
      s <- File.read!("input.txt") |> String.split("\n", trim: true),
      do: s
    )
  end

  def count_characters(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.reduce(%{}, fn codepoint, acc ->
        Map.update(acc, codepoint, 1, & &1 + 1)
    end)
  end

  def part1() do
    Enum.map(read_input(), fn s ->
      to_charlist(s)
      |> Enum.sort()
      |> Enum.sort()
      |> Enum.chunk_by(& &1)
      |> Enum.filter(&(length(&1) == 3 or length(&1) == 2))
      |> Enum.map(&Enum.dedup(&1))
      |> Enum.dedup()
    end)

    # |> Enum.reduce(0, fn s, accum ->
    #   accum +
    #     length(
    #       to_charlist(s)
    #       |> Enum.sort()
    #       |> Enum.chunk_by(& &1)
    #       |> Enum.filter(&(length(&1) == 3 or length(&1) == 2))
    #       |> Enum.map(&Enum.dedup(&1))
    #       |> Enum.dedup()
    #     )

    read_input()
    |> Enum.reduce(0, fn s, accum
        # Regex.run/3 with this regex returns the first letter occurring >= 2 times in s
        when length(Regex.run(~r/(?=([a-z])[^\1]*\1)/U, s, capture: :all_but_first)) > 0 -> accum + 1
        # Regex.scan/3 with the same regex puts a letter into a list each time it occurs more than or equal to 2 times in s
        # so the below code joins that list into a new string and then uses the same letter again to check if any of them occurs >= 2 times
        when length(Regex.run(~r/(?=([a-z])[^\1]*\1)/U, Enum.join(Regex.scan(~r/(?=([a-z])[^\1]*\1)/U, s, capture: :all_but_first)), capture: :all_but_first)) > 0 -> accum + 1
        true -> accum
    end)

      # length(Enum.dedup(Enum.map(Enum.filter(Enum.chunk_by(Enum.sort(to_charlist("bababaaaadfee")), &(&1)), &(length(&1) == 3 or length(&1) == 2)), &(Enum.dedup(&1)))))
  end
end

Day2.part1()
