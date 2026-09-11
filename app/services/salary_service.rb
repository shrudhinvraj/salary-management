# Encapsulates the business rule for salary changes:
#
#   * The first salary for an employee takes effect on their hire date.
#   * Any subsequent salary takes effect on a given date (default: today).
#     The previously active salary is closed on the day before the new one
#     starts, so the effective-date timeline stays gapless.
#
# All salary changes must flow through this service so the timeline invariant
# is enforced in one place.
class SalaryService
  Result = Struct.new(:salary, :errors, keyword_init: true) do
    def success?
      errors.empty?
    end
  end

  attr_reader :employee, :params

  def initialize(employee, params = {})
    @employee = employee
    @params = params
  end

  # Assigns an initial salary (used by the seeder and on employee creation).
  def self.assign_initial(employee, amount:, currency:, effective_from: nil, created_by: nil)
    new(employee, amount: amount, currency: currency, effective_from: effective_from, created_by: created_by).create_initial
  end

  # Creates an adjustment to the current salary of the employee.
  def self.adjust(employee, amount:, currency: nil, effective_from: nil, reason: nil, created_by: nil)
    new(
      employee,
      amount: amount,
      currency: currency,
      effective_from: effective_from,
      reason: reason,
      created_by: created_by
    ).create_adjustment
  end

  def create_initial
    return failure("employee must be persisted") unless employee.persisted?

    effective_from = (params[:effective_from] || employee.hire_date || Date.current).to_date
    currency = params[:currency] || employee.country.currency

    salary = employee.salaries.build(
      amount: params[:amount],
      currency: currency,
      amount_usd: usd_amount(params[:amount], currency),
      effective_from: effective_from,
      reason: "Initial salary",
      created_by: params[:created_by]
    )

    persist(salary)
  end

  def create_adjustment
    return failure("employee must be persisted") unless employee.persisted?

    currency = params[:currency] || employee.country.currency
    effective_from = (params[:effective_from] || Date.current).to_date
    reason = params[:reason].presence || "Salary adjustment"

    amount = params[:amount]
    return failure("amount is required") if amount.blank?

    current = employee.current_salary
    return failure("employee has no current salary to adjust; use create_initial instead") if current.nil?
    return failure("effective_from cannot be in the past") if effective_from < Date.current

    result = nil
    ActiveRecord::Base.transaction do
      current.update!(effective_to: effective_from - 1.day)

      new_salary = employee.salaries.build(
        amount: amount,
        currency: currency,
        amount_usd: usd_amount(amount, currency),
        effective_from: effective_from,
        reason: reason,
        created_by: params[:created_by]
      )

      if new_salary.save
        result = Result.new(salary: new_salary, errors: [])
      else
        employee.salaries.reset
        result = Result.new(salary: nil, errors: new_salary.errors.full_messages)
        raise ActiveRecord::Rollback
      end
    end

    result
  rescue ActiveRecord::RecordInvalid => e
    employee.salaries.reset
    Result.new(salary: nil, errors: [ e.record.errors.full_messages.join(", ") ])
  end

  private

  def usd_amount(amount, currency)
    rate = exchange_rate(currency)
    (amount.to_d * rate).round(2)
  end

  def exchange_rate(currency)
    country = Country.find_by(currency: currency)
    country ? country.exchange_rate_usd.to_d : 1.0
  end

  def persist(salary)
    if salary.save
      Result.new(salary: salary, errors: [])
    else
      Result.new(salary: salary, errors: salary.errors.full_messages)
    end
  end

  def failure(message)
    Result.new(salary: nil, errors: [ message ])
  end
end