defmodule Day1 do
  # most efficient form, using File.stream!() to read the file line by line
  def final_frequency_stream(file_stream) do
    file_streamman
    |> Stream.map(fn line ->
        {integer, _leftover} = Integer.parse(line)
        integer
      end)
    |> Enum.sum()
  end

  def final_frequency(input) do
    input
    # efficient operation using Stream (lazy computation -- not executed until later)
    |> String.splitter("\n", trim: true) # splits string on demand instead of all at once
    |> Stream.map(fn line -> String.to_integer(line) end) # creates a stream that will apply the given function when enumerated
    # You could be explicit and do
    # |> Enum.to_list()
    |> Enum.sum() # but it's not quite as efficient -- either way, you have to use Enum to make the Stream concrete at the end

    # naive Enum usage (requires whole file scan each time you call map or sum)
    # |> String.split("\n", trim: true)
    # |> IO.inspect(label: "split")
    # |> Enum.map(fn line -> String.to_integer(line) end)
    # |> IO.inspect(label: "map")
    # |> Enum.sum()
    #|> sum_lines(0) # naive recursion
  end

  defp sum_lines([line | lines], current_frequency) do
    new_frequency = String.to_integer(line) + current_frequency
    sum_lines(lines, new_frequency)
  end

  defp sum_lines([], current_frequency) do
    current_frequency
  end
end

case System.argv() do
  ["--test"] ->
    ExUnit.start()

  defmodule Day1Test do
    use ExUnit.Case

    import Day1

    test "final_frequency" do
      {:ok, io} = StringIO.open("""
        +1
        +1
        +1
        """)

      assert final_frequency_stream(IO.stream(io, :line)) === 3
    end
  end

  [input_file] ->
    input_file
    # low-memory-usage version: using Stream to read file line by line
    # (uses more CPU though! For small lists, Enum is going to be better -- clearer code w/
    # no discernible performance diff)
    |> File.stream!([], :line)
    # memory-hog version: loading whole file into memory
    #|> File.read!()

    |> Day1.final_frequency_stream()
    |> IO.puts

  _ ->
    IO.puts :stderr, "we expected --test or an input file"
    System.halt(1)
end
