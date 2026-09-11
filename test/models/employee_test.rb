require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  test "requires employee_code" do
    employee = build_employee(employee_code: nil)
    assert_not employee.valid?
    assert_includes employee.errors[:employee_code], "can't be blank"
  end

  test "requires unique employee_code" do
    code = "EMP-TEST-UNIQUE"
    create_employee(employee_code: code)
    duplicate = build_employee(employee_code: code)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:employee_code], "has already been taken"
  end

  test "requires valid email" do
    employee = build_employee(email: "not-an-email")
    assert_not employee.valid?
    assert_includes employee.errors[:email], "is invalid"
  end

  test "requires unique email" do
    email = "unique#{SecureRandom.hex(4)}@acme.com"
    create_employee(email: email)
    duplicate = build_employee(email: email)
    assert_not duplicate.valid?
  end

  test "requires a valid status" do
    employee = build_employee(status: "retired")
    assert_not employee.valid?
    assert_includes employee.errors[:status], "is not included in the list"
  end

  test "requires a valid gender" do
    employee = build_employee(gender: "other")
    assert_not employee.valid?
    assert_includes employee.errors[:gender], "is not included in the list"
  end

  test "search scope matches code, name, and email" do
    create_employee(first_name: "Zara", last_name: "Quinn", email: "zara.q@acme.com", employee_code: "EMP-AAA01")
    create_employee(first_name: "Bob", last_name: "Zara", email: "bob.z@acme.com", employee_code: "EMP-AAA02")

    assert_includes Employee.search("Zara").pluck(:first_name), "Zara"
    assert_equal 2, Employee.search("zara").count
    assert_equal 1, Employee.search("EMP-AAA01").count
    assert_equal 1, Employee.search("bob.z@acme.com").count
  end

  test "by_department scope filters" do
    engineering = create_department(name: "Engineering #{SecureRandom.hex(3)}")
    design = create_department(name: "Design #{SecureRandom.hex(3)}")
    create_employee(department: engineering)
    create_employee(department: design)

    assert_equal 1, Employee.by_department(engineering.id).count
  end

  test "by_country scope filters" do
    us = create_country
    india = create_country(code: "IN#{SecureRandom.hex(3)}", name: "India #{SecureRandom.hex(3)}", currency: "INR", exchange_rate_usd: 0.012)
    create_employee(country: us)
    create_employee(country: india)

    assert_equal 1, Employee.by_country(india.id).count
  end

  test "by_status scope filters" do
    create_employee(status: "active")
    create_employee(status: "terminated")

    assert_equal 1, Employee.by_status("terminated").count
    assert_equal 1, Employee.active.count
  end

  test "full_name combines first and last name" do
    employee = create_employee(first_name: "Ada", last_name: "Lovelace")
    assert_equal "Ada Lovelace", employee.full_name
  end

  test "current_salary returns the open-ended salary record" do
    employee = create_employee
    create_salary(employee, amount: 10_000, effective_from: Date.new(2023, 1, 1), effective_to: Date.new(2023, 12, 31))
    create_salary(employee, amount: 12_000, effective_from: Date.new(2024, 1, 1))

    current = employee.current_salary
    assert_equal 12_000, current.amount.to_i
    assert current.current?
  end

  test "current_salary returns nil when no salary exists" do
    employee = create_employee
    assert_nil employee.current_salary
  end

  test "age_as_of computes correctly" do
    employee = create_employee(birth_date: Date.new(1990, 6, 1))
    assert_equal 36, employee.age_as_of(Date.new(2026, 9, 11))
  end

  test "tenure_years uses hire date" do
    employee = create_employee(hire_date: Date.new(2020, 1, 1))
    assert_equal 6, employee.tenure_years
  end
end