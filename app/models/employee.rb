class Employee < ApplicationRecord
  STATUSES = %w[active on_leave terminated].freeze
  GENDERS = %w[male female non_binary].freeze

  belongs_to :country
  belongs_to :department
  has_many :salaries, -> { order(effective_from: :desc) }, dependent: :destroy

  validates :employee_code, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :gender, inclusion: { in: GENDERS }
  validates :status, inclusion: { in: STATUSES }
  validates :job_title, presence: true
  validates :hire_date, presence: true

  scope :search, ->(term) do
    return all if term.blank?

    q = "%#{term.to_s.strip.downcase}%"
    where(
      "lower(employee_code) LIKE :q OR lower(first_name) LIKE :q OR lower(last_name) LIKE :q OR lower(email) LIKE :q",
      q: q
    )
  end

  scope :by_department, ->(id) { id.present? ? where(department_id: id) : all }
  scope :by_country, ->(id) { id.present? ? where(country_id: id) : all }
  scope :by_status, ->(status) { status.present? ? where(status: status) : all }
  scope :active, -> { where(status: "active") }

  def full_name
    "#{first_name} #{last_name}"
  end

  def current_salary
    salaries.find { |s| s.current? }
  end

  def age_as_of(date = Date.current)
    return if birth_date.nil?

    years = date.year - birth_date.year
    years -= 1 if date < birth_date + years.years
    years
  end

  def tenure_years
    return 0 if hire_date.nil?

    ((Date.current - hire_date).days.in_years).floor
  end
end