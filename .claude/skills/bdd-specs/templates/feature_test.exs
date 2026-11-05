defmodule MyAppWeb.Controllers.<Controller>.<Action>Test do
  use MyAppWeb.ConnCase, async: true

  test "<happy path behaviour, in plain words>", %{conn: conn} do
    league = insert(:league)
    season = insert(:season, league: league)

    response =
      conn
      |> get("/api/v3/<route>?season_id=#{season.external_id}")
      |> json_response(200)

    assert %{"data" => [_ | _]} = response
  end

  test "<second happy path behaviour>", %{conn: conn} do
    player = build_ranked_player()

    response =
      conn
      |> get("/api/v3/<route>")
      |> json_response(200)

    assert [%{"id" => player_id}] = response["data"]
    assert player_id == player.external_id
  end

  test "<sad path behaviour, e.g. an unknown season returns not found>", %{conn: conn} do
    conn = get(conn, "/api/v3/<route>?season_id=#{System.unique_integer([:positive])}")

    assert json_response(conn, 404)
  end

  defp build_ranked_player do
    player = insert(:player)
    insert(:gradient_ranking, player: player)
    player
  end
end
