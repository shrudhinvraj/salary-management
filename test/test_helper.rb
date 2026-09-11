ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  self.use_transactional_tests = true

  # ── Test factories (kept deliberately simple) ─────────────────────────
  def create_country(attrs = {})
    Country.create!({
      code: "US#{SecureRandom.hex(2)}",
      name: "United States #{SecureRandom.hex(2)}",
      currency: "USD",
      exchange_rate_usd: 1.0
    }.merge(attrs))
  end

  def create_department(attrs = {})
    Department.create!({ name: "Engineering #{SecureRandom.hex(2)}" }.merge(attrs))
  end

  def build_employee(attrs = {})
    country = attrs.delete(:country) || create_country
    department = attrs.delete(:department) || create_department

    Employee.new({
      employee_code: "EMP-#{format('%05d', SecureRandom.random_number(100_000))}",
      first_name: "Jane",
      last_name: "Smith",
      email: "jane.smith#{SecureRandom.hex(4)}@acme.com",
      gender: "female",
      job_title: "Software Engineer",
      status: "active",
      hire_date: Date.new(2020, 1, 15),
      country: country,
      department: department
    }.merge(attrs))
  end

  def create_employee(attrs = {})
    build_employee(attrs).tap(&:save!)
  end

  def create_salary(employee, attrs = {})
    employee.salaries.create!({
      amount: 12_000,
      amount_usd: 12_000,
      currency: "USD",
      effective_from: employee.hire_date
    }.merge(attrs))
  end
end