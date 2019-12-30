defmodule IntegrationSuite do
  require Logger

  @root File.cwd!()
        |> Path.split()
        |> IO.inspect()
        |> (&Enum.split(&1, 1 + Enum.find_index(&1, fn p -> p == "elm-json-diff" end))).()
        |> elem(0)
        |> Path.join()
        |> Path.join("test_data")

  def generate_diffs() do
    grouped_json_files =
      Path.wildcard("#{@root}/*.*.json")
      |> Enum.map(fn file_name -> String.split(Path.basename(file_name), ".") end)
      |> Enum.group_by(fn list_of_basename_parts -> Enum.at(list_of_basename_parts, 0) end)
      |> Enum.map(fn {concept, matching_files_in_concept} ->
        {concept,
         Enum.sort(matching_files_in_concept)
         |> Enum.map(fn parts -> Enum.join(parts, ".") end)}
      end)

    Logger.info("Grouped json #{inspect(grouped_json_files, pretty: true)}")

    functions = [
      {:simple_diff, &JsonDiffLogic.SimpleDiff.diff/2},
      {:sorted_key_diff, &JsonDiffLogic.SortedKeyDiff.diff/2}
    ]

    grouped_json_files
    |> Enum.map(fn {concept, files} ->
      [left, right | _] = files
      left_json = File.read!(Path.join(@root, left))
      right_json = File.read!(Path.join(@root, right))

      functions
      |> Enum.map(fn {function_name, diff_function} ->
        Logger.info("Calling #{inspect(diff_function)} on #{left_json}, #{right_json}")
        result = diff_function.(left_json, right_json)

        File.write!(
          Path.join([@root, "test_diff_results", "#{concept}.#{function_name}.result.json"]),
          inspect(result, pretty: true)
        )
      end)

      Logger.info("Concept(#{concept}) -> left(#{left}), right(#{right}))")
    end)
  end
end
