class Api::V1::BaseController < ActionController::API
  MAX_PER_PAGE = 100

  private

  def pagination_params
    {
      page: [ params[:page].to_i, 1 ].max,
      per_page: [ params[:per_page].to_i, 1 ].max.clamp(1, MAX_PER_PAGE)
    }
  end

  def render_errors(record)
    render json: { errors: Array(record.errors.full_messages) }, status: :unprocessable_entity
  end

  def render_not_found(resource = "record")
    render json: { errors: [ "#{resource} not found" ] }, status: :not_found
  end
end