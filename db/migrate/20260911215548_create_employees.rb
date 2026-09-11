class CreateEmployees < ActiveRecord::Migration[7.2]
  def change
    create_table :employees do |t|
      t.string :employee_code, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :gender, null: false
      t.string :job_title, null: false
      t.string :status, null: false, default: "active"
      t.date :hire_date, null: false
      t.date :birth_date
      t.references :country, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true

      t.timestamps
    end

    add_index :employees, :employee_code, unique: true
    add_index :employees, :email, unique: true
    add_index :employees, :status
    add_index :employees, :job_title
  end
end