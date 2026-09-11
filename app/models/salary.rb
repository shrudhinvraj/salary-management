class Salary < ApplicationRecord
  CURRENCIES = %w[USD EUR GBP INR JPY AUD CAD SGD].freeze

  belongs_to :employee

  validates :amount, numericality: { greater_than: 0 }
  validates :amount_usd, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :effective_from, presence: true

  validate :effective_to_after_effective_from, if: -> { effective_to.present? }
  validate :no_overlap_with_existing_records, on: :create

  scope :active, -> { where(effective_to: nil) }
  scope :as_of, ->(date) do
    where("effective_from <= :date AND (effective_to IS NULL OR effective_to >= :date)", date: date)
  end

  def current?
    effective_to.nil?
  end

  def closes?(other)
    !current? && effective_to == other.effective_from - 1.day
  end

  private

  def effective_to_after_effective_from
    return if effective_to.nil? || effective_to >= effective_from

    errors.add(:effective_to, "must be on or after effective_from")
  end

  def no_overlap_with_existing_records
    return unless employee
    return if effective_from.nil?

    end_of_time = Date.new(9999, 12, 31)
    period_end = effective_to || end_of_time
    overlapping = employee.salaries.any? do |existing|
      existing.id != id &&
        existing.effective_from <= period_end &&
        effective_from <= (existing.effective_to || end_of_time)
    end
    errors.add(:effective_from, "overlaps an existing salary period") if overlapping
  end
end