require "test_helper"

class Api::V1::ExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @employee = create_employee(first_name: "Export", last_name: "Test")
    create_salary(@employee, amount: 12_000, amount_usd: 12_000, currency: "USD", effective_from: @employee.hire_date)
  end

  test "employees export returns CSV with headers and data" do
    get "/api/v1/exports/employees"

    assert_response :success
    assert_equal "text/csv; charset=utf-8", response.headers["Content-Type"]

    csv = CSV.parse(response.body, headers: true)
    assert_equal "employee_code", csv.headers.first
    assert_equal 1, csv.size
    assert_equal @employee.employee_code, csv[0]["employee_code"]
    assert_equal "12000.00", csv[0]["monthly_salary"]
    assert_equal "12000.00", csv[0]["monthly_salary_usd"]
  end
end