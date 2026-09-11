require "test_helper"

class SalaryServiceTest < ActiveSupport::TestCase
  test "assign_initial creates the first salary on the hire date" do
    employee = create_employee(hire_date: Date.new(2021, 5, 10))
    country = create_country(currency: "GBP", exchange_rate_usd: 1.27)

    outcome = SalaryService.assign_initial(employee, amount: 6_000, currency: "GBP")

    assert outcome.success?
    salary = employee.salaries.first
    assert_equal Date.new(2021, 5, 10), salary.effective_from
    assert_equal 6_000, salary.amount.to_i
    assert_equal 7_620, salary.amount_usd.to_i
    assert salary.current?
  end

  test "assign_initial uses an explicit effective_from when given" do
    employee = create_employee(hire_date: Date.new(2021, 5, 10))
    outcome = SalaryService.assign_initial(employee, amount: 5_000, currency: "USD", effective_from: Date.new(2022, 1, 1))

    assert outcome.success?
    assert_equal Date.new(2022, 1, 1), employee.salaries.first.effective_from
  end

  test "assign_initial requires a persisted employee" do
    outcome = SalaryService.assign_initial(Employee.new, amount: 5_000, currency: "USD")
    refute outcome.success?
    assert_equal [ "employee must be persisted" ], outcome.errors
  end

  test "adjust closes the current salary and opens a new one" do
    employee = create_employee
    create_salary(employee, amount: 10_000, effective_from: Date.new(2023, 1, 1))

    outcome = SalaryService.adjust(employee, amount: 12_000, currency: "USD", effective_from: Date.current, reason: "Promotion")

    assert outcome.success?
    assert_equal 2, employee.salaries.count

    old, new = employee.salaries.reorder(effective_from: :asc).to_a
    refute old.current?
    assert_equal Date.current - 1.day, old.effective_to
    assert new.current?
    assert_equal 12_000, new.amount.to_i
    assert_equal "Promotion", new.reason
  end

  test "adjust rejects past effective dates" do
    employee = create_employee
    create_salary(employee, amount: 10_000)

    outcome = SalaryService.adjust(employee, amount: 12_000, currency: "USD", effective_from: Date.yesterday)

    refute outcome.success?
    assert_includes outcome.errors, "effective_from cannot be in the past"
    assert_equal 1, employee.salaries.count
  end

  test "adjust rejects missing amount" do
    employee = create_employee
    create_salary(employee, amount: 10_000)

    outcome = SalaryService.adjust(employee, amount: nil, currency: "USD")

    refute outcome.success?
    assert_includes outcome.errors, "amount is required"
  end

  test "adjust fails when employee has no current salary" do
    employee = create_employee
    outcome = SalaryService.adjust(employee, amount: 12_000, currency: "USD")
    refute outcome.success?
    assert_includes outcome.errors, "employee has no current salary to adjust; use create_initial instead"
  end

  test "adjust rolls back the closing when the new salary is invalid" do
    employee = create_employee
    create_salary(employee, amount: 10_000)

    outcome = SalaryService.adjust(employee, amount: -5, currency: "USD", effective_from: Date.current)

    refute outcome.success?
    assert employee.current_salary.present?
    assert_equal 10_000, employee.current_salary.amount.to_i
    assert_equal 1, employee.salaries.count
  end
end