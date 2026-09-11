class SalarySerializer
  def self.as_json(salary)
    {
      id: salary.id,
      amount: salary.amount.to_f,
      amount_usd: salary.amount_usd.to_f,
      currency: salary.currency,
      effective_from: salary.effective_from.iso8601,
      effective_to: salary.effective_to&.iso8601,
      current: salary.current?,
      reason: salary.reason,
      created_by: salary.created_by,
      created_at: salary.created_at.iso8601
    }
  end

  def self.as_json_collection(salaries)
    salaries.map { |s| as_json(s) }
  end
end