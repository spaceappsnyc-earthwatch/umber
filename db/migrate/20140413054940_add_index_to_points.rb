class AddIndexToPoints < ActiveRecord::Migration
  def up
    execute %{
      create index index_on_points_location ON points using gist (
        ST_GeographyFromText(
          'SRID=4326;POINT(' || points.longitude || ' ' || points.latitude || ')'
        )
      )
    }
  end

  def down
    execute %{drop index index_on_points_location}
  end
end
