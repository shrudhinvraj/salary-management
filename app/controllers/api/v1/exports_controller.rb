require "csv"

class Api::V1::ExportsController < Api::V1::BaseController
  HEADERS = %w[
    employee_code first_name last_name email gender job_title status
    hire_date department country currency monthly_salary monthly_salary_usd
  ].freeze

  def employees
    employees = Employee.includes(:department, :country, :salaries).search(params[:q]).order(:employee_code)

    csv = CSV.generate(headers: true) do |csv|
      csv << HEADERS
      employees.find_each do |employee|
        current = employee.current_salary
        csv << [
          employee.employee_code,
          employee.first_name,
          employee.last_name,
          employee.email,
          employee.gender,
          employee.job_title,
          employee.status,
          employee.hire_date,
          employee.department&.name,
          employee.country&.name,
          employee.country&.currency,
          current ? format("%.2f", current.amount) : "",
          current ? format("%.2f", current.amount_usd) : ""
        ]
      end
    end

    send_data csv, type: "text/csv; charset=utf-8", filename: "employees_#{Date.current}.csv"
  end
end