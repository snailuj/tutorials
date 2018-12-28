defmodule Day2 do
  #for this challenge, recursion turns out to be the fastest for part 2 because we can traverse
  #both the charlist of the current ID we are trying to find a match for, and the match candidate
  #at the same time
  def closest_recursive(list) when is_list(list) do
    list
    |> Enum.map(&String.to_charlist/1)
    |> closest_charlist_recursive()
  end

  def closest_charlist_recursive([head | tail]) do
    Enum.find_value(tail, &string_if_similar_recursive(&1, head)) || closest_charlist_recursive(tail)
  end

  #initial case, when only given two charlists
  defp string_if_similar_recursive(charlist1, charlist2) do
    string_if_similar_recursive(charlist1, charlist2, [], 0)
  end

  #pattern match on same head
  defp string_if_similar_recursive([head | tail1], [head | tail2], same_acc, difference_count) do
    string_if_similar_recursive(tail1, tail2, [head | same_acc], difference_count)
  end

  #pattern match on different head
  defp string_if_similar_recursive([_ | tail1], [_ | tail2], same_acc, difference_count) do
    string_if_similar_recursive(tail1, tail2, same_acc, difference_count + 1)
  end

  #base case, found a match
  defp string_if_similar_recursive([], [], same_acc, 1) do
    #reverse because we have been prepending to the head of the list all the time (in 'same head' clause above)
    same_acc |> Enum.reverse() |> List.to_string()
  end

  #base case, not a match
  defp string_if_similar_recursive([], [], _, _) do
    nil
  end

  def closest2(list) when is_list(list) do
    list
    |> Enum.map(&String.to_charlist/1)
    |> closest_charlists2()
  end

  defp closest_charlists2([head | tail]) do
    Enum.find_value(tail, &string_if_similar(&1, head)) || closest_charlists2(tail)
  end

  defp string_if_similar(charlist1, charlist2) do
    charlist1
    |> Enum.zip(charlist2)
    |> Enum.split_with(fn {cp1, cp2} -> cp1 == cp2 end)
    |> case do
      {all_equal, [_]} ->
        all_equal
        |> Enum.map(fn {cp, _} -> cp end)
        |> List.to_string()

      {_, _} ->
        nil
    end
  end

  def closest(list) when is_list(list) do
    list
    |> Enum.map(&String.to_charlist/1)
    |> closest_charlists()
  end

  defp closest_charlists([head | tail]) do
    if closest = Enum.find(tail, &one_char_difference?(&1, head)) do
      head
      |> Enum.zip(closest)
      |> Enum.filter(fn {cp1, cp2} -> cp1 == cp2 end)
      |> Enum.map(fn {cp, _} -> cp end)
      |> List.to_string()
    else
      closest_charlists(tail)
    end
  end

  defp one_char_difference?(charlist1, charlist2) do
    charlist1
    |> Enum.zip(charlist2)
    |> Enum.count(fn {cp1, cp2} -> cp1 != cp2 end)
    # this is ugly, some people get upset about it but works
    |> Kernel.==(1)
  end

  def checksum(list) when is_list(list) do
    {twices, thrices} =
      list
      |> Enum.reduce({0, 0}, fn box_id, {total_twice, total_thrice} ->
        {twice, thrice} = box_id |> count_characters() |> get_twice_and_thrice()
        {twice + total_twice, thrice + total_thrice}
      end)

    twices * thrices
  end

  def get_twice_and_thrice(characters) when is_map(characters) do
    # This is how he would actually write it because he's always trying to write the most
    # optimised code he can... not the clearest, but the fastest because you only traverse the chars once
    Enum.reduce(characters, {0, 0}, fn
      # if count for that char is 2 then set twice to 1
      {_codepoint, 2}, {_twice, thrice} -> {1, thrice}
      # else if count for that char is 3, set thrice to 1
      {_codepoint, 3}, {twice, _thrice} -> {twice, 1}
      # anything else, just return the accumulator
      _, acc -> acc
    end)
  end

  # set up clause
  def count_characters(string) when is_binary(string) do
    count_characters(string, %{})
  end

  # pattern matching on a string. Analogous to [ head | tail ] with a list
  # by specifying it as codepoint::utf8, Elixir will actually traverse the graphemes!
  # otherwise it will traverse the string byte-by-byte
  # using to_charlist would be more performant
  defp count_characters(<<codepoint::utf8, rest::binary>>, acc) do
    acc = Map.update(acc, codepoint, 1, &(&1 + 1))
    count_characters(rest, acc)
  end

  # matches when binary is empty
  defp count_characters(<<>>, acc) do
    acc
  end
end
