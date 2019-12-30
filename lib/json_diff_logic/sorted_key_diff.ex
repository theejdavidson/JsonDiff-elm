defmodule JsonDiffLogic.SortedKeyDiff do
  import JsonDiffLogic.JsonDiffHelpers
  def diff(jsonTextA, jsonTextB) do
    {parsedA, parsedB} = parse_json_strings(jsonTextA, jsonTextB)

    a = recursive_flatten(parsedA)
    b = recursive_flatten(parsedB)

    %{
      matched_pairs: [
        %{
          key: "street_address",
          # value: "1232 Martin Luthor King Dr"
          value: 1232
        }
      ],
      mismatched_values: [
        %{
          key: "city",
          value_a: "Smallville",
          value_b: "Bigville"
        },
        %{
          key: "street",
          value_a: "Smallville2",
          value_b: "Bigville2"
        }
      ],
      missing_from_a: [
        %{key: "aValue", value: "Foo"}
      ],
      missing_from_b: [
        %{key: "bValue", value: "Bar"}
      ]
    }
  end
end
