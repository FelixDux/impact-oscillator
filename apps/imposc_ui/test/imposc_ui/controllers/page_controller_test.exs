defmodule ImposcUi.PageControllerTest do
  use ImposcUi.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Impact Oscillator"
  end
end
