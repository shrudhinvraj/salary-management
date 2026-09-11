class Api::V1::EmployeesController < Api::V1::BaseController
  before_action :set_employee, only: [ :show, :update, :destroy, :salaries ]

  def index
    scope = Employee
      .includes(:country, :department, :salaries)
      .search(params[:q])
      .by_department(params[:department_id])
      .by_country(params[:country_id])
      .by_status(params[:status])
      .order("first_name ASC, last_name ASC")

    total = scope.count
    page, per_page = pagination_params.values_at(:page, :per_page)
    employees = scope.offset((page - 1) * per_page).limit(per_page)

    render json: {
      data: EmployeeSerializer.as_json_collection(employees),
      meta: { total: total, page: page, per_page: per_page, total_pages: (total.to_f / per_page).ceil }
    }
  end

  def show
    render json: { data: EmployeeSerializer.as_json(@employee) }
  end

  def create
    employee = Employee.new(employee_params.merge(employee_code: next_employee_code))

    if employee.save
      outcome = SalaryService.assign_initial(
        employee,
        amount: params[:salary][:amount],
        currency: params[:salary][:currency],
        created_by: params[:salary][:created_by]
      )

      if outcome.success?
        render json: { data: EmployeeSerializer.as_json(employee) }, status: :created, location: api_v1_employee_url(employee)
      else
        employee.destroy
        render_errors_with_messages(outcome.errors)
      end
    else
      render_errors(employee)
    end
  end

  def update
    if @employee.update(employee_params)
      render json: { data: EmployeeSerializer.as_json(@employee) }
    else
      render_errors(@employee)
    end
  end

  def destroy
    if @employee.salaries.empty?
      @employee.destroy
      head :no_content
    else
      render json: { errors: [ "Cannot delete an employee with salary history" ] }, status: :unprocessable_entity
    end
  end

  def salaries
    render json: { data: SalarySerializer.as_json_collection(@employee.salaries) }
  end

  private

  def set_employee
    @employee = Employee.includes(:country, :department, :salaries).find_by(id: params[:id])
    render_not_found("employee") unless @employee
  end

  def employee_params
    params.require(:employee).permit(:first_name, :last_name, :email, :gender, :job_title, :status, :hire_date, :department_id, :country_id, :birth_date)
  end

  def next_employee_code
    last = Employee.order(employee_code: :desc).pick(:employee_code)
    seq = last ? last.delete_prefix("EMP-").to_i + 1 : 1
    "EMP-#{format("%05d", seq)}"
  end

  def render_errors_with_messages(messages)
    render json: { errors: Array(messages) }, status: :unprocessable_entity
  end
end