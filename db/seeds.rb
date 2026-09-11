# frozen_string_literal: true

# Seeds 10,000 employees for the ACME Salary Manager demo.
#
# Run:  rails db:seed
#   or  rails runner "load 'db/seeds.rb'"
#
# Seeding is idempotent: running it twice creates no duplicate employees.

puts "🌱 Seeding ACME Salary Manager…"
puts "   Countries…"

countries_data = [
  { code: "US", name: "United States", currency: "USD", rate: 1.0 },
  { code: "UK", name: "United Kingdom", currency: "GBP", rate: 1.27 },
  { code: "DE", name: "Germany", currency: "EUR", rate: 1.09 },
  { code: "FR", name: "France", currency: "EUR", rate: 1.09 },
  { code: "IN", name: "India", currency: "INR", rate: 0.012 },
  { code: "JP", name: "Japan", currency: "JPY", rate: 0.0067 },
  { code: "AU", name: "Australia", currency: "AUD", rate: 0.65 },
  { code: "CA", name: "Canada", currency: "CAD", rate: 0.74 },
  { code: "SG", name: "Singapore", currency: "SGD", rate: 0.74 },
  { code: "BR", name: "Brazil", currency: "USD", rate: 1.0 },
  { code: "NL", name: "Netherlands", currency: "EUR", rate: 1.09 },
  { code: "IE", name: "Ireland", currency: "EUR", rate: 1.09 }
]

countries = countries_data.map do |d|
  Country.find_or_create_by!(code: d[:code]) do |c|
    c.name = d[:name]
    c.currency = d[:currency]
    c.exchange_rate_usd = d[:rate]
  end
end

puts "   Departments…"
department_names = %w[
  Engineering Product Design Marketing Sales Finance
  Human Resources Legal Operations Customer Success Data Science
  DevOps Security Infrastructure QA Research
]

departments = department_names.map do |name|
  Department.find_or_create_by!(name: name)
end

puts "   Job titles…"
job_titles = [
  "Software Engineer", "Senior Software Engineer", "Staff Engineer",
  "Engineering Manager", "Product Manager", "Senior Product Manager",
  "Designer", "Senior Designer", "Design Lead",
  "Data Analyst", "Data Scientist", "ML Engineer",
  "QA Engineer", "DevOps Engineer", "Security Engineer",
  "Marketing Manager", "Content Strategist", "Growth Lead",
  "Account Executive", "Account Manager", "Sales Manager",
  "HR Business Partner", "Recruiter", "People Operations Lead",
  "Finance Analyst", "Financial Controller", "Legal Counsel",
  "Operations Manager", "Support Engineer", "Solutions Architect",
  "Research Scientist", "Technical Writer", "Scrum Master",
  "Infrastructure Engineer", "Backend Engineer", "Frontend Engineer",
  "Mobile Developer", "Platform Engineer", "CTO", "VP of Engineering"
]

# Salary ranges by country and seniority tier (monthly local currency)
# Tier: junior=1, mid=2, senior=3, lead=4
SALARY_RANGES = {
  "USD" => { 1 => [5_000, 8_000],  2 => [8_000, 13_000],  3 => [13_000, 18_000],  4 => [18_000, 25_000] },
  "GBP" => { 1 => [3_500, 6_000],  2 => [6_000, 10_000],  3 => [10_000, 14_000],  4 => [14_000, 20_000] },
  "EUR" => { 1 => [4_000, 6_500],  2 => [6_500, 10_500],  3 => [10_500, 15_000],  4 => [15_000, 21_000] },
  "INR" => { 1 => [40_000, 80_000], 2 => [80_000, 160_000], 3 => [160_000, 280_000], 4 => [280_000, 450_000] },
  "JPY" => { 1 => [280_000, 420_000], 2 => [420_000, 650_000], 3 => [650_000, 900_000], 4 => [900_000, 1_200_000] },
  "AUD" => { 1 => [5_500, 8_500], 2 => [8_500, 13_000], 3 => [13_000, 18_000], 4 => [18_000, 24_000] },
  "CAD" => { 1 => [5_000, 7_500], 2 => [7_500, 11_500], 3 => [11_500, 16_000], 4 => [16_000, 22_000] },
  "SGD" => { 1 => [4_500, 7_000], 2 => [7_000, 11_000], 3 => [11_000, 15_000], 4 => [15_000, 20_000] }
}

# Assign seniority tier from title
def title_to_tier(title)
  t = title.downcase
  return 4 if %w[lead manager director vp cto].any? { |k| t.include?(k) }
  return 3 if %w[senior staff principal staff].any? { |k| t.include?(k) }
  return 1 if %w[junior].any? { |k| t.include?(k) }
  2
end

used_emails = Set.new(Employee.pluck(:email))
used_codes  = Set.new(Employee.pluck(:employee_code))
seq = Employee.maximum(:employee_code)&.delete_prefix("EMP-")&.to_i || 0

EMPLOYEES_COUNT = 10_000
BATCH_SIZE = 500
printed_sample = false

EMPLOYEES_COUNT.times do |i|
  seq += 1
  code = "EMP-#{format('%05d', seq)}"
  country = countries.sample
  department = departments.sample
  title = job_titles.sample
  gender = %w[male female non_binary].sample
  status = rand(100) < 93 ? "active" : rand(100) < 50 ? "on_leave" : "terminated"
  hire_date = Date.new(2015, 1, 1) + rand((Date.new(2025, 12, 31) - Date.new(2015, 1, 1)).to_i).days
  birth_date = hire_date - rand(22..45).years

  # Ensure unique email
  base_email = "#{Faker::Internet.unique.username(specifier: 8..12, separators: %w[_ .])}@acme.com"
  attempt = 0
  while used_emails.include?(base_email)
    attempt += 1
    base_email = "user#{seq}@acme.com"
    break if attempt > 5
  end
  used_emails.add(base_email)
  used_codes.add(code)

  tier = title_to_tier(title)
  range = SALARY_RANGES[country.currency][tier]
  initial_amount = rand(range[0]..range[1]).to_d.round(2)
  rate = country.exchange_rate_usd.to_d
  amount_usd = (initial_amount * rate).round(2)

  first = Faker::Name.first_name
  last  = Faker::Name.last_name

  employee = Employee.create!(
    employee_code: code,
    first_name: first,
    last_name: last,
    email: base_email,
    gender: gender,
    job_title: title,
    status: status,
    hire_date: hire_date,
    birth_date: birth_date,
    country: country,
    department: department
  )

  employee.salaries.create!(
    amount: initial_amount,
    amount_usd: amount_usd,
    currency: country.currency,
    effective_from: hire_date,
    effective_to: status == "terminated" ? hire_date + rand(6..24).months : nil,
    reason: "Initial salary",
    created_by: "system-seed"
  )

  # Create 1-3 historical salary adjustments for ~40% of employees
  if rand < 0.4 && employee.status == "active"
    adjustment_count = rand(1..3)
    current_effective = hire_date + rand(6..18).months

    adjustment_count.times do
      break if current_effective > Date.current - 30.days

      new_amount = (initial_amount * rand(1.05..1.20)).round(2)
      prev = employee.salaries.last
      prev.update!(effective_to: current_effective - 1.day) if prev

      employee.salaries.create!(
        amount: new_amount,
        amount_usd: (new_amount * rate).round(2),
        currency: country.currency,
        effective_from: current_effective,
        reason: %w[annual_review promotion reclassification market_adjustment salary_revision].sample.gsub("_", " ").capitalize,
        created_by: %w[HR.Admin.Johnson HR.Dir.Chen Manager.Smith].sample
      )
      initial_amount = new_amount
      current_effective += rand(6..18).months
    end
  end

  print "\r   Employees: #{i + 1}/#{EMPLOYEES_COUNT}    " if (i + 1) % 500 == 0
end

puts "\n✅ Done! #{Employee.count} employees, #{Salary.count} salary records created."
puts "   Countries: #{Country.count}  |  Departments: #{Department.count}"
puts ""
puts "   Sample accounts:"
puts "     employee_code  |  email               |  department  |  country"
puts "     " + "-" * 65
Employee.includes(:department, :country, :salaries).order("RANDOM()").limit(5).each do |e|
  cur = e.current_salary
  amt = cur ? "#{cur.amount} #{cur.currency}" : "—"
  puts "     %-13s | %-20s | %-12s | %-10s | %s" % [e.employee_code, e.email, e.department.name, e.country.name, amt]
end