defmodule JsonDiffWeb.DiffController do
  use JsonDiffWeb, :controller

  def diff(conn, _params) do
    render(conn, "diff.html")
  end
end
