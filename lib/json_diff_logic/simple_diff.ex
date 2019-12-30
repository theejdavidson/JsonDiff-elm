defmodule JsonDiffLogic.SimpleDiff do
  def diff(nil, nil), do: :same

  def diff(nil, _a), do: :todo
  def diff(_a, nil), do: :todo

  def diff(json_a, json_b) when is_binary(json_a) and is_binary(json_b) do
    IO.puts("Diffing #{json_a} vs #{json_b}")

    if(json_a == json_b) do
      :same
    else
      json_a <> json_b
    end
  end

  def diff(json_a, json_b) when is_number(json_a) and is_number(json_b) do
    if(json_a == json_b) do
      :same
    else
      json_a + json_b
    end
  end

  def diff(json_a, json_b) when is_map(json_a) and is_map(json_b) do
    if(json_a == json_b) do
      :same
    else
      Map.merge(json_a, json_b)
    end
  end

  def diff(json_a, json_b) when is_boolean(json_a) and is_boolean(json_b) do
    if(json_a == json_b) do
      :same
    else
      json_a || json_b
    end
  end
end
