require "test_helper"

class Api::V1::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @country = create_country
    @department = create_department
    employee = create_employee(country: @country, department: @department)
    create_salary(employee, amount: 10_000, amount_usd: 10_000, currency: "USD", effective_from: employee.hire_date)
  end

  test "show returns analytics with all facets" do
    get "/api/v1/analytics"
    body = JSON.parse(response.body)

    assert_response :success
    data = body["data"]
    assert_equal 1, data.dig("summary", "total_employees")
    assert_equal 10_000, data.dig("summary", "average_monthly_salary_usd")
    assert_equal 1, data["by_department"].length
    assert_equal 1, data["by_country"].length
    assert_equal 1, data["by_job_title"].length
    assert_equal 1, data["by_gender"].length
  end
end