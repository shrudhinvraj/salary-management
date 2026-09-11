class Api::V1::SalariesController < Api::V1::BaseController
  before_action :set_employee

  def index
    render json: { data: SalarySerializer.as_json_collection(@employee.salaries) }
  end

  def create
    outcome = SalaryService.adjust(
      @employee,
      amount: params[:amount],
      currency: params[:currency],
      effective_from: params[:effective_from],
      reason: params[:reason],
      created_by: params[:created_by]
    )

    if outcome.success?
      render json: { data: SalarySerializer.as_json(outcome.salary) }, status: :created
    else
      render json: { errors: outcome.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_employee
    @employee = Employee.includes(:salaries, :country).find_by(id: params[:employee_id])
    render_not_found("employee") unless @employee
  end
end