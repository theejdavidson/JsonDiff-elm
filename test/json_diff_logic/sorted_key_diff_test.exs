defmodule JsonDiffLogic.SortedKeyDiffTest do
    
    use ExUnit.Case
    alias JsonDiffLogic.SortedKeyDiff
  
    test "sorted key diff" do
        assert SortedKeyDiff.diff(1, 1) == :same
        assert SortedKeyDiff.diff(true, true) == :same
        assert SortedKeyDiff.diff(false, false) == :same
        assert SortedKeyDiff.diff(nil, nil) == :same
        assert SortedKeyDiff.diff("foo", "foo") == :same
        assert SortedKeyDiff.diff(%{}, %{}) == :same
    end
  end