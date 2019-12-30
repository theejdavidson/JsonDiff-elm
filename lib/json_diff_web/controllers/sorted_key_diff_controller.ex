defmodule JsonDiffWeb.SortedKeyDiffController do
  use JsonDiffWeb, :controller
  require Logger

  def diff(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      200,
      Jason.encode!(%{
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
      })
    )
  end

  def sorted_key_diff(conn, json) do
    Logger.info("inputJson is #{inspect(json, pretty: true)}")

    %{"jsonTextA" => jsonTextA, "jsonTextB" => jsonTextB} = json

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      200,
      Jason.encode!(JsonDiffLogic.SortedKeyDiff.diff(jsonTextA, jsonTextB))
    )
  end
end
