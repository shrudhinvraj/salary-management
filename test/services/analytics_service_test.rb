require "test_helper"

class AnalyticsServiceTest < ActiveSupport::TestCase
  setup do
    @us = create_country(currency: "USD", exchange_rate_usd: 1.0)
    @uk = create_country(currency: "GBP", exchange_rate_usd: 1.27)
    @eng = create_department(name: "Engineering #{SecureRandom.hex(3)}")
    @sales = create_department(name: "Sales #{SecureRandom.hex(3)}")
  end

  test "summary computes payroll statistics over current salaries" do
    engineer = create_employee(department: @eng, country: @us)
    create_salary(engineer, amount: 10_000, amount_usd: 10_000, currency: "USD")

    salesperson = create_employee(department: @sales, country: @uk)
    create_salary(salesperson, amount: 8_000, amount_usd: 10_160, currency: "GBP")

    service = AnalyticsService.new
    summary = service.summary.payload

    assert_equal 2, summary[:total_employees]
    assert_equal 2, summary[:employees_paid]
    assert_equal 10_080.to_f.round(2), summary[:average_monthly_salary_usd].to_f
    assert_equal 20_160.to_f.round(2), summary[:monthly_payroll_usd].to_f
    assert_equal 241_920.to_f.round(2), summary[:annual_payroll_usd].to_f
  end

  test "summary handles an empty database" do
    summary = AnalyticsService.new.summary.payload
    assert_equal 0, summary[:total_employees]
    assert_equal 0, summary[:average_monthly_salary_usd]
    assert_equal 0, summary[:monthly_payroll_usd]
  end

  test "by_department groups correct headcounts and payroll" do
    eng1 = create_employee(department: @eng, country: @us)
    eng2 = create_employee(department: @eng, country: @us)
    create_salary(eng1, amount: 10_000, amount_usd: 10_000, currency: "USD")
    create_salary(eng2, amount: 12_000, amount_usd: 12_000, currency: "USD")

    sales1 = create_employee(department: @sales, country: @us)
    create_salary(sales1, amount: 8_000, amount_usd: 8_000, currency: "USD")

    rows = AnalyticsService.new.by_department

    engineering = rows.find { |r| r[:key] == @eng.name }
    sales = rows.find { |r| r[:key] == @sales.name }

    assert_equal 2, engineering[:headcount]
    assert_equal 11_000.to_f.round(2), engineering[:average_monthly_salary_usd]
    assert_equal 1, sales[:headcount]
  end

  test "by_country reports currency-converted figures" do
    us_emp = create_employee(department: @eng, country: @us)
    create_salary(us_emp, amount: 10_000, amount_usd: 10_000, currency: "USD")

    uk_emp = create_employee(department: @eng, country: @uk)
    create_salary(uk_emp, amount: 7_000, amount_usd: 8_890, currency: "GBP")

    rows = AnalyticsService.new.by_country

    uk = rows.find { |r| r[:key] == @uk.name }
    assert_equal 8_890.to_f.round(2), uk[:average_monthly_salary_usd]
  end
end