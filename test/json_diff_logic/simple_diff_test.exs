defmodule JsonDiffLogic.SimpleDiffTest do
  use ExUnit.Case
  alias JsonDiffLogic.SimpleDiff

  test "simple diff" do
    assert SimpleDiff.diff(1, 1) == :same
    assert SimpleDiff.diff(true, true) == :same
    assert SimpleDiff.diff(false, false) == :same
    assert SimpleDiff.diff(nil, nil) == :same
    assert SimpleDiff.diff("foo", "foo") == :same
    assert SimpleDiff.diff(%{}, %{}) == :same
  end
end
