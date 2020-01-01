defmodule JsonDiffLogic.SortedKeyDiff do
  import JsonDiffLogic.JsonDiffHelpers
  require Logger

  def diff(jsonTextA, jsonTextB) do
    {parsedA, parsedB} = parse_json_strings(jsonTextA, jsonTextB)

    a = recursive_flatten(parsedA)
    b = recursive_flatten(parsedB)

    Logger.info("a is\n #{inspect(a, pretty: true)}\nb is\n#{inspect(b, pretty: true)}")

    result =
      a
      |> Enum.reduce(
        %{
          matched_pairs: [],
          mismatched_values: [],
          missing_from_a: [],
          missing_from_b: []
        },
        fn {path, a_value}, acc ->
          cond do
            Map.has_key?(b, path) ->
              b_value = Map.get(b, path)

              if(b_value == a_value) do
                %{acc | matched_pairs: [to_pair(path, a_value) | acc.matched_pairs]}
              else
                %{
                  acc
                  | mismatched_values: [
                      %{
                        key: Enum.join(path, "."),
                        value_a: a_value,
                        value_b: b_value
                      }
                      | acc.mismatched_values
                    ]
                }
              end

            true ->
              %{acc | missing_from_b: [to_pair(path, a_value) | acc.missing_from_b]}
          end
        end
      )

    result =
      b
      |> Enum.reduce(result, fn {path, b_value}, acc ->
        if(Map.has_key?(a, path)) do
          acc
        else
          %{acc | missing_from_a: [to_pair(path, b_value) | acc.missing_from_a]}
        end
      end)

      result = %{
        matched_pairs: Enum.sort(result.matched_pairs),
        mismatched_values: Enum.sort(result.mismatched_values),
        missing_from_a: Enum.sort(result.missing_from_a),
        missing_from_b: Enum.sort(result.missing_from_b)
      }

    Logger.info("Reduced to #{inspect(result, pretty: true)}")

    result
  end
end
