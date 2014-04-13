class PointsController < ApplicationController
  respond_to :json

  before_filter :find_dataset

  def index
    latitude = Float(params[:latitude])
    longitude = Float(params[:longitude]) + 180
    time = DateTime.parse(params[:time])

    lat_delta = 8.0
    lon_delta = 12.0

    lat_range = (latitude - lat_delta)...(latitude + lat_delta)
    lon_range = (longitude - lon_delta)...(longitude + lon_delta)

    @points = @dataset.points.where(latitude: lat_range, longitude: lon_range, time: time)
    #@points = @dataset.points.close_to(latitude, longitude, 1_000_000).where(time: time)
    #respond_with @points.map{ |p| [ p.longitude - 180, p.latitude ] }

    @results = {
      max_value: @points.map(&:value).max,
      min_value: @points.map(&:value).min,
      value_name: @points.first.value_name,

      points: @points.map do |p|
        {
          longitude: p.longitude - 180,
          latitude: p.latitude,
          value: p.value
        }
      end
    }

    respond_with @results
  end

  def times
    @times = @dataset.points.select(:time).uniq.pluck(:time).uniq.sort
    respond_with @times
  end

  private

  def find_dataset
    @dataset = Dataset.find(params[:dataset_id])
  end
end
