require 'csv'

class ChartsController < ApplicationController

  def index
  end

  def create
    builder = ChartBuilderService.new(params[:input_file].tempfile)
    @builds_series = builder.builds_series
    @duration_series = builder.duration_series
  end
end
