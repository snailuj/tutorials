defmodule Day3 do
  @type claim :: String.t()
  @type parsed_claim :: list
  @type coordinate :: {pos_integer, pos_integer}
  @type id :: integer

  @doc """
  Parses a claim

  ## Examples

      iex> Day3.parse_claim("#1292 @ 811,139: 8x4")
      [1292, 811, 139, 8, 4]

  """
  @spec parse_claim(claim) :: parsed_claim
  def parse_claim(string) when is_binary(string) do
    string
    |> String.split(["#", " @ ", ",", ": ", "x"], trim: true)
    |> Enum.map(&String.to_integer/1)
  end

  @doc """
  Retrieves all claimed inches

  ## Examples

      iex> claimed = Day3.claimed_inches([
      ...>  [1, 1, 3, 4, 4],
      ...>  [2, 3, 1, 4, 4],
      ...>  [3, 5, 5, 2, 2]
      ...>])
      iex> claimed[{4, 2}]
      [2]
      iex> claimed[{4, 4}] |> Enum.sort
      [1, 2]
  """
  @spec claimed_inches([parsed_claim]) :: %{coordinate => [id]}
  def claimed_inches(parsed_claims) do
    Enum.reduce(parsed_claims, %{}, fn [id, left, top, width, height], acc ->
      Enum.reduce((left + 1)..(left + width), acc, fn x, acc ->
        Enum.reduce((top + 1)..(top + height), acc, fn y, acc ->
          Map.update(acc, {x, y}, [id], &[id | &1])
        end)
      end)
    end)
  end

  @doc """
  Retrieves overlapped inches.

  ## Examples
    iex> Day3.overlapped_inches([
    ...>  [1, 1, 3, 4, 4],
    ...>  [2, 3, 1, 4, 4],
    ...>  [3, 5, 5, 2, 2],
    ...>]) |> Enum.sort()
    [{4, 4}, {4, 5}, {5, 4}, {5, 5}]
  """
  @spec overlapped_inches([parsed_claim]) :: [coordinate]
  def overlapped_inches(parsed_claims) do
    # just use a comprehension to collect all claimed inches that have 2 or more ids in their list
    # pattern matches any inch that has more than one item in its sublist
    for {coordinate, [_, _ | _]} <- claimed_inches(parsed_claims), do: coordinate
  end

  @doc """
  Retrieves the item with no overlap.

  STOP PRESS: turns out this is actually faster than the next one?!

  ## Examples
    iex> Day3.no_overlap([
    ...>  "#1 @ 1,3: 4x4",
    ...>  "#2 @ 3,1: 4x4",
    ...>  "#3 @ 5,5: 2x2",
    ...>])
    3
  """
  @spec no_overlap([claim]) :: id
  def no_overlap(claims) do
    parsed_claims = Enum.map(claims, &parse_claim/1)
    claimed_inches = claimed_inches(parsed_claims)

    [id, _, _, _, _] =
      Enum.find(parsed_claims, fn [id, left, top, width, height] ->
        Enum.all?((left + 1)..(left + width), fn x ->
          Enum.all?((top + 1)..(top + height), fn y ->
            Map.get(claimed_inches, {x, y}) == [id]
          end)
        end)
      end)

    id
  end

  @doc """
  Retrieves the item with no overlap

  ## Examples
    iex> Day3.no_overlap_not_so_fast_after_all([
    ...>  "#1 @ 1,3: 4x4",
    ...>  "#2 @ 3,1: 4x4",
    ...>  "#3 @ 5,5: 2x2",
    ...>])
    3
  """
  # @spec no_overlap([claim]) :: id
  def no_overlap_not_so_fast_after_all(claims) do
    # assume none are overlapping to begin with
    not_overlapping = MapSet.new(1..length(claims))

    {_inches, not_overlapping} =
      Enum.reduce(claims, {%{}, not_overlapping}, fn claim, acc ->
        [id, left, top, width, height] = parse_claim(claim)

        Enum.reduce((left + 1)..(left + width), acc, fn x, acc ->
          Enum.reduce((top + 1)..(top + height), acc, fn y, {inches, not_overlapping} ->
            coordinate = {x, y}

            not_overlapping =
              case inches do
                # ^coordinate syntax "pins" a variable so that you don't rebind it to a new value
                # otherwise the pattern matcher would be too greedy and match on the first
                # coordinate that has a single-element list, whereas we want to only match if the
                # coordinate WE ALREADY DEFINED as {x, y} maps to a single-element list

                #if you already have one id assigned to this co-ord in `inches` then remove it from
                #the set of not overlappings, and remove the current id as well
                %{^coordinate => [unique_id]} ->
                  not_overlapping |> MapSet.delete(unique_id) |> MapSet.delete(id)

                %{^coordinate => _} ->
                  not_overlapping |> MapSet.delete(id)

                %{} ->
                  not_overlapping
              end

            {Map.update(inches, coordinate, [id], &[id | &1]), not_overlapping}
          end)
        end)
      end)

    [id] = MapSet.to_list(not_overlapping)
    id
  end
end
