require "test_helper"

class SalaryTest < ActiveSupport::TestCase
  test "requires a positive amount" do
    employee = create_employee
    salary = build_salary(employee, amount: 0)
    assert_not salary.valid?
    assert_includes salary.errors[:amount], "must be greater than 0"
  end

  test "requires currency" do
    salary = build_salary(create_employee, currency: nil)
    assert_not salary.valid?
    assert_includes salary.errors[:currency], "can't be blank"
  end

  test "requires effective_from" do
    salary = build_salary(create_employee, effective_from: nil)
    assert_not salary.valid?
    assert_includes salary.errors[:effective_from], "can't be blank"
  end

  test "requires effective_to to be on or after effective_from" do
    salary = build_salary(create_employee, effective_from: Date.new(2024, 1, 1), effective_to: Date.new(2023, 1, 1))
    assert_not salary.valid?
    assert_includes salary.errors[:effective_to], "must be on or after effective_from"
  end

  test "allows effective_to equal to effective_from" do
    salary = build_salary(create_employee, effective_from: Date.new(2024, 1, 1), effective_to: Date.new(2024, 1, 1))
    assert salary.valid?
  end

  test "rejects overlapping salary periods on create" do
    employee = create_employee
    create_salary(employee, effective_from: Date.new(2023, 1, 1), effective_to: Date.new(2023, 12, 31))

    overlap = build_salary(employee, effective_from: Date.new(2023, 6, 1), effective_to: Date.new(2024, 6, 1))
    assert_not overlap.valid?
    assert_includes overlap.errors[:effective_from], "overlaps an existing salary period"
  end

  test "is current when effective_to is nil" do
    salary = create_salary(create_employee)
    assert salary.current?
  end

  test "is not current when effective_to is set" do
    salary = create_salary(create_employee, effective_to: Date.new(2025, 12, 31))
    refute salary.current?
  end

  test "active scope only returns open-ended salaries" do
    employee = create_employee
    create_salary(employee, effective_from: Date.new(2023, 1, 1), effective_to: Date.new(2023, 12, 31))
    create_salary(employee, effective_from: Date.new(2024, 1, 1))

    assert_equal 1, Salary.active.count
  end

  test "as_of scope returns salaries that cover a given date" do
    employee = create_employee
    create_salary(employee, effective_from: Date.new(2023, 1, 1), effective_to: Date.new(2024, 12, 31))
    create_salary(employee, effective_from: Date.new(2025, 1, 1))

    assert_equal 1, Salary.as_of(Date.new(2024, 6, 15)).count
  end

  private

  def build_salary(employee, attrs = {})
    employee.salaries.build({
      amount: 12_000,
      amount_usd: 12_000,
      currency: "USD",
      effective_from: Date.new(2024, 1, 1)
    }.merge(attrs))
  end
end