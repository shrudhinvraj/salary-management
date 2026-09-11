# Aggregates salary data for the HR dashboard. All monetary figures are
# monthly amounts expressed in USD for cross-country comparison.
class AnalyticsService
  Result = Struct.new(:payload, keyword_init: true)

  def initialize
    @salary_rows = current_salary_rows
  end

  def summary
    stats = {
      total_employees: Employee.count,
      active_employees: Employee.active.count,
      terminated_employees: Employee.where(status: "terminated").count,
      average_monthly_salary_usd: mean(amounts),
      median_monthly_salary_usd: median(amounts),
      min_monthly_salary_usd: (amounts.min || 0).to_f.round(2),
      max_monthly_salary_usd: (amounts.max || 0).to_f.round(2),
      monthly_payroll_usd: amounts.sum.to_f.round(2),
      annual_payroll_usd: (amounts.sum * 12).to_f.round(2),
      countries_count: Country.count,
      departments_count: Department.count,
      employees_paid: @salary_rows.size
    }
    Result.new(payload: stats)
  end

  def by_department
    group_stats(:department)
  end

  def by_country
    group_stats(:country)
  end

  def by_job_title
    group_stats(:job_title)
  end

  def by_gender
    group_stats(:gender)
  end

  def all
    {
      summary: summary.payload,
      by_department: by_department,
      by_country: by_country,
      by_job_title: by_job_title,
      by_gender: by_gender
    }
  end

  private

  def current_salary_rows
    Employee.joins(:salaries)
      .where(salaries: { effective_to: nil })
      .select(
        "employees.id",
        "employees.department_id",
        "employees.country_id",
        "employees.job_title",
        "employees.gender",
        "salaries.amount_usd"
      )
  end

  def amounts
    @amounts ||= @salary_rows.map { |r| r.amount_usd.to_d }
  end

  def group_stats(facet)
    facet_table = {
      department: [ "departments.name AS label", "employees.department_id" ],
      country: [ "countries.name AS label", "employees.country_id" ],
      job_title: [ "employees.job_title AS label", "employees.job_title" ],
      gender: [ "employees.gender AS label", "employees.gender" ]
    }
    select_clause, group_clause = facet_table.fetch(facet)

    rows = Employee.joins(:salaries)
      .joins(:department)
      .joins(:country)
      .where(salaries: { effective_to: nil })
      .group(group_clause)
      .select(
        select_clause,
        "COUNT(employees.id) AS headcount",
        "ROUND(AVG(salaries.amount_usd), 2) AS average_monthly_salary_usd",
        "ROUND(SUM(salaries.amount_usd), 2) AS monthly_payroll_usd"
      )
      .order("monthly_payroll_usd DESC")

    rows.map do |r|
      {
        key: r.label,
        headcount: r.headcount,
        average_monthly_salary_usd: r.average_monthly_salary_usd.to_f.round(2),
        monthly_payroll_usd: r.monthly_payroll_usd.to_f.round(2)
      }
    end
  end

  def mean(values)
    return 0 if values.empty?

    (values.sum / values.size).round(2).to_f
  end

  def median(values)
    return 0 if values.empty?

    sorted = values.sort
    mid = sorted.size / 2
    if sorted.size.odd?
      sorted[mid].round(2).to_f
    else
      ((sorted[mid - 1] + sorted[mid]) / 2).round(2).to_f
    end
  end
end