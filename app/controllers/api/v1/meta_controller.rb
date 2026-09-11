class Api::V1::MetaController < Api::V1::BaseController
  def index
    render json: {
      data: {
        countries: Country.order(:name).map { |c| { id: c.id, code: c.code, name: c.name, currency: c.currency } },
        departments: Department.order(:name).map { |d| { id: d.id, name: d.name } },
        statuses: Employee::STATUSES,
        genders: Employee::GENDERS
      }
    }
  end
end