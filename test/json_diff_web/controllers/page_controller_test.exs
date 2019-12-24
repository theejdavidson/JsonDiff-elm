defmodule JsonDiffWeb.PageControllerTest do
  use JsonDiffWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")

    assert html_response(conn, 200)
           |> String.contains?("JsonDiff")
  end
end
