require "test_helper"

class Api::V1::EmployeesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @country = create_country
    @department = create_department
    @employee = create_employee(country: @country, department: @department, hire_date: Date.new(2019, 3, 1))
    create_salary(@employee, amount: 12_000, amount_usd: 12_000, currency: "USD", effective_from: @employee.hire_date)
  end

  test "index returns paginated employees with meta" do
    get "/api/v1/employees", params: { page: 1, per_page: 1 }
    body = JSON.parse(response.body)

    assert_response :success
    assert_equal 1, body["data"].length
    assert_equal 1, body.dig("meta", "total")
    assert_equal 1, body.dig("meta", "page")
    assert_equal 1, body.dig("meta", "total_pages")
  end

  test "index filters by search term" do
    create_employee(first_name: "UniqueName", email: "unique#{SecureRandom.hex(4)}@acme.com")

    get "/api/v1/employees", params: { q: "UniqueName" }
    body = JSON.parse(response.body)

    assert_equal 1, body.dig("meta", "total")
    assert_equal "UniqueName", body.dig("data", 0, "first_name")
  end

  test "index filters by department" do
    other = create_department(name: "Other #{SecureRandom.hex(3)}")
    create_employee(department: other)

    get "/api/v1/employees", params: { department_id: @department.id }
    body = JSON.parse(response.body)

    assert_equal 1, body.dig("meta", "total")
    assert_equal @department.name, body.dig("data", 0, "department")
  end

  test "index filter by status" do
    create_employee(status: "terminated")

    get "/api/v1/employees", params: { status: "terminated" }
    body = JSON.parse(response.body)

    assert_equal 1, body.dig("meta", "total")
  end

  test "index caps per_page at 100" do
    101.times do |i|
      create_employee(employee_code: "EMP-CAP#{format('%03d', i)}", email: "cap#{i}@acme.com")
    end

    get "/api/v1/employees", params: { per_page: 500 }
    body = JSON.parse(response.body)

    assert_equal 100, body["data"].length
    assert_equal 100, body.dig("meta", "per_page")
  end

  test "show returns full employee with current salary" do
    get "/api/v1/employees/#{@employee.id}"
    body = JSON.parse(response.body)

    assert_response :success
    data = body["data"]
    assert_equal @employee.employee_code, data["employee_code"]
    assert_equal 12_000, data.dig("current_salary", "amount")
    assert data.dig("current_salary", "current")
  end

  test "show returns 404 for a missing employee" do
    get "/api/v1/employees/999999"
    assert_response :not_found
  end

  test "create adds an employee with an initial salary" do
    assert_difference [ "Employee.count", "Salary.count" ] do
      post "/api/v1/employees",
        params: {
          employee: {
            first_name: "Grace", last_name: "Hopper", email: "grace#{SecureRandom.hex(4)}@acme.com",
            gender: "female", job_title: "Engineer", hire_date: "2022-04-01",
            department_id: @department.id, country_id: @country.id
          },
          salary: { amount: 9_500 }
        }
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Grace", body.dig("data", "first_name")
    assert_equal 9_500, body.dig("data", "current_salary", "amount")
  end

  test "create rejects invalid employee data" do
    post "/api/v1/employees",
      params: {
        employee: { first_name: "", last_name: "", email: "bad" },
        salary: { amount: 5_000 }
      }

    assert_response :unprocessable_entity
  end

  test "create rejects missing salary amount" do
    post "/api/v1/employees",
      params: {
        employee: {
          first_name: "Grace", last_name: "Hopper", email: "grace2#{SecureRandom.hex(4)}@acme.com",
          gender: "female", job_title: "Engineer", hire_date: "2022-04-01",
          department_id: @department.id, country_id: @country.id
        },
        salary: { amount: nil }
      }

    assert_response :unprocessable_entity
    assert_equal 0, Employee.where(first_name: "Grace").count
  end

  test "update changes employee attributes" do
    patch "/api/v1/employees/#{@employee.id}", params: { employee: { first_name: "Ada" } }
    body = JSON.parse(response.body)

    assert_response :success
    assert_equal "Ada", body.dig("data", "first_name")
  end

  test "destroy refuses employees with salary history" do
    delete "/api/v1/employees/#{@employee.id}"
    assert_response :unprocessable_entity
  end

  test "destroy succeeds for employees without salary history" do
    fresh = create_employee
    assert_difference "Employee.count", -1 do
      delete "/api/v1/employees/#{fresh.id}"
    end
    assert_response :no_content
  end
end