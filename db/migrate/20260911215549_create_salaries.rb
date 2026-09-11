class CreateSalaries < ActiveRecord::Migration[7.2]
  def change
    create_table :salaries do |t|
      t.references :employee, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.decimal :amount_usd, precision: 12, scale: 2, null: false
      t.string :currency, null: false
      t.date :effective_from, null: false
      t.date :effective_to
      t.string :reason
      t.string :created_by

      t.timestamps
    end

    add_index :salaries, [ :employee_id, :effective_from ]
    add_index :salaries, :effective_to
    add_index :salaries, [ :effective_to, :employee_id ]
  end
end