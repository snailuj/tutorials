defmodule Day1 do
  # most efficient form, using File.stream!() to read the file line by line
  def repeated_frequency(file_stream) do
    # Total hack, using "the Process map" as global state
    # DO NOT USE in the wild. But fastest possible execution
    # Task.async( fn ->
    #   Process.put({__MODULE__, 0}, true)

      file_stream
      |> Stream.map(fn line ->
          {integer, _leftover} = Integer.parse(line)
          integer
        end)
      |> Stream.cycle() #cycles the stream infinitely
      |> Enum.reduce_while(0, fn x, current_frequency ->
          new_frequency = current_frequency + x
          key = {__MODULE__, new_frequency}

          if Process.get(key) do
            {:halt, new_frequency}
          else
            Process.put({__MODULE__, new_frequency}, true)
            {:cont, new_frequency}
          end
        end)
    #end) |> Task.await(:infinity)
  end
end

case System.argv() do
  ["--test"] ->
    ExUnit.start()

  defmodule Day1Test do
    use ExUnit.Case

    import Day1

    test "final_frequency" do
      assert repeated_frequency([ #can't use StringIO to create a stream if using Stream.cycle because it won't cycle
        "+1\n",
        "-2\n",
        "+3\n",
        "+1\n"
      ]) === 2
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

    |> Day1.repeated_frequency()
    |> IO.puts

  _ ->
    IO.puts :stderr, "we expected --test or an input file"
    System.halt(1)
end
