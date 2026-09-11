# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_09_11_215549) do
  create_table "countries", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "currency", null: false
    t.decimal "exchange_rate_usd", precision: 10, scale: 4, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "employees", force: :cascade do |t|
    t.string "employee_code", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "gender", null: false
    t.string "job_title", null: false
    t.string "status", default: "active", null: false
    t.date "hire_date", null: false
    t.date "birth_date"
    t.integer "country_id", null: false
    t.integer "department_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_employees_on_country_id"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_code"], name: "index_employees_on_employee_code", unique: true
    t.index ["job_title"], name: "index_employees_on_job_title"
    t.index ["status"], name: "index_employees_on_status"
  end

  create_table "salaries", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.decimal "amount_usd", precision: 12, scale: 2, null: false
    t.string "currency", null: false
    t.date "effective_from", null: false
    t.date "effective_to"
    t.string "reason"
    t.string "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["effective_to", "employee_id"], name: "index_salaries_on_effective_to_and_employee_id"
    t.index ["effective_to"], name: "index_salaries_on_effective_to"
    t.index ["employee_id", "effective_from"], name: "index_salaries_on_employee_id_and_effective_from"
    t.index ["employee_id"], name: "index_salaries_on_employee_id"
  end

  add_foreign_key "employees", "countries"
  add_foreign_key "employees", "departments"
  add_foreign_key "salaries", "employees"
end
