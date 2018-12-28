defmodule Day2Test do
  use ExUnit.Case

  doctest Day2

  test "count_characters" do
    assert Day2.count_characters("aabbcc") == %{
      ?a => 2, #?a means the codepoint for 'a'
      ?b => 2,
      ?c => 2
    }
  end
end
