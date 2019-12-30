defmodule JsonDiffWeb.SortedKeyDiffController do
    use JsonDiffWeb, :controller

    def diff(conn, _params) do
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(
           %{
             matched_pairs: [
               %{
               key: "street_address",
               #value: "1232 Martin Luthor King Dr"
               value: 1232
               }
             ]#,
        #     matched_keys: [
        #       %{
        #         key: "city",
        #         value_a: "Smallville",
        #         value_b: "Bigville"
        #       }
        #     ]
           }
        ))
    end
end
