defmodule JsonDiffLogic.JsonDiffHelpers do
  @moduledoc """
  Documentation for ExJsonDiff.
  """

  @doc """
  Takes two strings with assumed valid json,
  parses each and returns parsed data as tuple.

  ## Examples

      iex> ExJsonDiff.parse_json_strings("1", "2")
      {1, 2}

      iex> ExJsonDiff.parse_json_strings("[1,2,3]", "[4,5,6]")
      { [1,2,3], [4,5,6] }
  """
  def parse_json_strings(a, b) do
    {Jason.decode!(a), Jason.decode!(b)}
  end

  @doc """
  Given parsed 'a' and 'b', finds the _semantic_ differences.
      iex> ExJsonDiff.diff_parsed_json(1, 1)
      :same

      iex> ExJsonDiff.diff_parsed_json(("foo"), ("foo"))
      :same

      iex> ExJsonDiff.diff_parsed_json(("foo"), ("bar"))
      :different

      iex> ExJsonDiff.diff_parsed_json([1, "foo"], [1, "foo"])
      :same
  """
  def diff_parsed_json(a, b) do
    if a == b do
      :same
    else
      :different
    end
  end

  @doc """
  Given the two strings 'a' and 'b',
  parses them and returns the _semantic_ differences.

  ## Examples

    iex> ExJsonDiff.diff_json_strings(~s("foo"), ~s("foo"))
    :same

    iex> ExJsonDiff.diff_json_strings(~s("foo"), ~s("bar"))
    :different
  """
  def diff_json_strings(a, b) do
    {a, b} = parse_json_strings(a, b)
    diff_parsed_json(a, b)
  end

  @doc """
  Returns true if the parsed data is a scalar
  In JSON the possible scalar data structures are:
  number, boolean, string

  ## Examples

      iex> ExJsonDiff.is_scalar(1)
      true

      iex>ExJsonDiff.is_scalar(false)
      true

      iex>ExJsonDiff.is_scalar("foo")
      true

      iex>ExJsonDiff.is_scalar([1, 2, 3])
      false

      iex>ExJsonDiff.is_scalar(%{a: "A", b: "B"})
      false
  """
  def is_scalar(nil), do: true

  def is_scalar(parsed) when is_number(parsed), do: true

  def is_scalar(parsed) when is_boolean(parsed), do: true

  def is_scalar(parsed) when is_binary(parsed), do: true

  def is_scalar(parsed) when is_list(parsed), do: false

  def is_scalar(parsed) when is_map(parsed), do: false

  def some_function(a, b, c) do
    IO.puts("a: #{inspect(a)}, b: #{inspect(b)}, c: #{inspect(c)}")
  end

  @doc """
  Takes `parsed` json data, scalar, list, object, etc. and
  returns a `map(list(binary), scalar)`

  ## Examples

      iex> import ExJsonDiff
      ...> recursive_flatten(3)
      %{[] => 3 }

      iex> import ExJsonDiff
      ...> recursive_flatten([1, 2, 3])
      %{[0] => 1, [1] => 2, [2] => 3}

      iex> import ExJsonDiff
      ...> recursive_flatten(Jason.decode!(~s({"a": {"b": {"c": "C"}, "d": [1,2,3]}})))
      %{
      ["a", "b", "c"] => "C",
      ["a", "d", 0] => 1,
      ["a", "d", 1] => 2,
      ["a", "d", 2] => 3
      }
  """
  def recursive_flatten(parsed) do
    cond do
      is_scalar(parsed) ->
        %{[] => parsed}

      is_list(parsed) ->
        parsed
        |> Enum.withIndex()
        |> Enum.map(fn {child, index} ->
          recursive_flatten(child)
          |> Enum.map(fn {path, value} -> {[index | path], value} end)
        end)
        |> List.flatten()
        |> Enum.into(%{})

      is_map(parsed) ->
        parsed
        |> Enum.map(fn {key, value} ->
          recursive_flatten(value)
          |> Enum.map(fn {path, value} -> {[key | path], value} end)
        end)
        |> List.flatten()
        |> Enum.into(%{})

      true ->
        raise "Unexpected type for `recursive_flatten` #{inspect(parsed)}"
    end
  end
end
