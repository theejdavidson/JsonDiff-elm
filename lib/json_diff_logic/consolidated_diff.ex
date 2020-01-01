defmodule JsonDiffLogic.ConsolidatedDiff do
  import JsonDiffLogic.JsonDiffHelpers
  require Logger

  def diff(jsonTextA, jsonTextB) do
    {parsedA, parsedB} = parse_json_strings(jsonTextA, jsonTextB)

    a = recursive_flatten(parsedA)
    b = recursive_flatten(parsedB)

    result =
      a
      |> Enum.reduce(
        [],
        fn {path, a_value}, acc ->
          new_element =
            cond do
              Map.has_key?(b, path) ->
                b_value = Map.get(b, path)

                if(b_value == a_value) do
                  %{
                    key: Enum.join(path, "."),
                    # One of { :matched_pair, :missing_in_a, :missing_in_b, :mismatched }
                    row_type: "matched_pair",
                    value: a_value,
                    other_value: nil
                  }
                else
                  %{
                    key: Enum.join(path, "."),
                    row_type: "mismatched",
                    value: a_value,
                    other_value: b_value
                  }
                end

              # b does not have key `path` 
              true ->
                %{
                  key: Enum.join(path, "."),
                  row_type: "missing_from_b",
                  value: a_value,
                  other_value: nil
                }
            end

          [new_element | acc]
        end
      )

    result = b
    |> Enum.reduce(result, fn {path, b_value}, acc ->
      if(Map.has_key?(a, path)) do
        acc
      else
        [
          %{
            key: Enum.join(path, "."),
            row_type: "missing_from_a",
            value: b_value,
            other_value: nil
          }
          | acc
        ]
      end
    end)
    |> Enum.sort(&(&1.key <= &2.key))

    Logger.info("Reduced to #{inspect(result, pretty: true)}")
    result
  end
end
