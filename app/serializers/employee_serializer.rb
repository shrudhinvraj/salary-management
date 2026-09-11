class EmployeeSerializer
  def self.as_json(employee)
    {
      id: employee.id,
      employee_code: employee.employee_code,
      first_name: employee.first_name,
      last_name: employee.last_name,
      full_name: employee.full_name,
      email: employee.email,
      gender: employee.gender,
      job_title: employee.job_title,
      status: employee.status,
      hire_date: employee.hire_date.iso8601,
      age: employee.age_as_of,
      tenure_years: employee.tenure_years,
      department_id: employee.department_id,
      department: employee.department&.name,
      country_id: employee.country_id,
      country: employee.country&.name,
      currency: employee.country&.currency,
      current_salary: employee.current_salary ? SalarySerializer.as_json(employee.current_salary) : nil
    }
  end

  def self.as_json_collection(employees)
    employees.map { |e| as_json(e) }
  end
end