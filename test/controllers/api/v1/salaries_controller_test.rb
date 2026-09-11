require "test_helper"

class Api::V1::SalariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @employee = create_employee
    create_salary(@employee, amount: 10_000, amount_usd: 10_000, currency: "USD", effective_from: @employee.hire_date)
  end

  test "index lists salary history newest first" do
    get "/api/v1/employees/#{@employee.id}/salaries"
    body = JSON.parse(response.body)

    assert_response :success
    assert_equal 1, body["data"].length
    assert_equal 10_000, body.dig("data", 0, "amount")
    assert body.dig("data", 0, "current")
  end

  test "create adjusts an employee's salary" do
    assert_difference "Salary.count", 1 do
      post "/api/v1/employees/#{@employee.id}/salaries",
        params: { amount: 13_500, effective_from: Date.current, reason: "Annual review" }
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal 13_500, body.dig("data", "amount")
    assert body.dig("data", "current")

    closed = @employee.salaries.reorder(effective_from: :asc).first
    refute closed.current?
    assert_equal Date.current - 1.day, closed.effective_to
  end

  test "create returns errors for an invalid amount" do
    post "/api/v1/employees/#{@employee.id}/salaries", params: { amount: -100, effective_from: Date.current }
    assert_response :unprocessable_entity
  end

  test "create returns 404 for a missing employee" do
    post "/api/v1/employees/999999/salaries", params: { amount: 5_000 }
    assert_response :not_found
  end
end