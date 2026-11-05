defmodule MyApp.Repo.Migrations.CreateTeamSeasonMetricTotals do
  use Ecto.Migration

  def up do
    execute("""
    CREATE MATERIALIZED VIEW team_season_metric_totals AS
    SELECT
      metric.sportsmonks_season_external_id,
      metric.sportsmonks_team_external_id,
      metric.metric_name,
      sum(metric.metric_value) AS metric_total
    FROM dat_teams_weekly_metrics AS metric
    GROUP BY
      metric.sportsmonks_season_external_id,
      metric.sportsmonks_team_external_id,
      metric.metric_name
    """)

    # REFRESH ... CONCURRENTLY requires a unique index on the view.
    execute("""
    CREATE UNIQUE INDEX team_season_metric_totals_unique_idx
    ON team_season_metric_totals (sportsmonks_season_external_id, sportsmonks_team_external_id, metric_name)
    """)
  end

  def down do
    execute("DROP MATERIALIZED VIEW IF EXISTS team_season_metric_totals")
  end
end
