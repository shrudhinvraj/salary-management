class Api::V1::AnalyticsController < Api::V1::BaseController
  def show
    render json: { data: AnalyticsService.new.all }
  end
end