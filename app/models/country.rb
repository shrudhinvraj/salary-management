class Country < ApplicationRecord
  has_many :employees, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :currency, presence: true
  validates :exchange_rate_usd, numericality: { greater_than: 0 }

  def to_s
    name
  end
end