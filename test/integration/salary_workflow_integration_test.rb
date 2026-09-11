require "test_helper"

# Exercises the full HR workflow end-to-end: create an employee, view the
# roster, adjust their salary, and verify the dashboard reflects it.
class SalaryWorkflowIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @country = create_country(currency: "USD", exchange_rate_usd: 1.0)
    @department = create_department(name: "Engineering #{SecureRandom.hex(3)}")
  end

  test "full HR salary management workflow" do
    # 1. HR creates a new employee with an initial salary
    post "/api/v1/employees",
      params: {
        employee: {
          first_name: "Margaret", last_name: "Hamilton", email: "m.hamilton#{SecureRandom.hex(3)}@acme.com",
          gender: "female", job_title: "Software Engineer", hire_date: "2023-06-15",
          department_id: @department.id, country_id: @country.id
        },
        salary: { amount: 8_000 }
      }
    assert_response :created
    employee_id = JSON.parse(response.body).dig("data", "id")

    # 2. HR sees the employee in the roster
    get "/api/v1/employees", params: { q: "Hamilton" }
    assert_equal 1, JSON.parse(response.body).dig("meta", "total")

    # 3. HR applies a promotion salary adjustment
    post "/api/v1/employees/#{employee_id}/salaries",
      params: { amount: 11_000, effective_from: Date.current, reason: "Promotion to Senior" }
    assert_response :created

    # Only the new salary is current; history remains intact
    get "/api/v1/employees/#{employee_id}/salaries"
    history = JSON.parse(response.body)["data"]
    assert_equal 2, history.length
    assert_equal 1, history.count { |s| s["current"] }
    assert_equal [ 11_000, 8_000 ], history.map { |s| s["amount"] }

    # 4. Dashboard includes the updated salary
    get "/api/v1/analytics"
    summary = JSON.parse(response.body).dig("data", "summary")
    assert_equal 11_000, summary["average_monthly_salary_usd"]
    assert_equal 132_000, summary["annual_payroll_usd"]
  end

  test "dashboard aggregates across multiple employees" do
    3.times do |i|
      employee = create_employee(department: @department, country: @country)
      create_salary(employee, amount: 10_000 + i * 1_000, amount_usd: 10_000 + i * 1_000, currency: "USD")
    end

    get "/api/v1/analytics"
    summary = JSON.parse(response.body).dig("data", "summary")
    assert_equal 3, summary["total_employees"]
    assert_equal 11_000, summary["average_monthly_salary_usd"]
    assert_equal 33_000, summary["monthly_payroll_usd"]
  end
end