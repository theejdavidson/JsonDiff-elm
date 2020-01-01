defmodule JsonDiffWeb.ConsolidatedDiffController do
    use JsonDiffWeb, :controller
    require Logger
  
    def consolidated_diff(conn, json) do
      Logger.info("inputJson is #{inspect(json, pretty: true)}")
  
      %{"jsonTextA" => jsonTextA, "jsonTextB" => jsonTextB} = json
  
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(JsonDiffLogic.ConsolidatedDiff.diff(jsonTextA, jsonTextB))
      )
    end
  end