class CreateCountries < ActiveRecord::Migration[7.2]
  def change
    create_table :countries do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :currency, null: false
      t.decimal :exchange_rate_usd, precision: 10, scale: 4, null: false, default: 1.0

      t.timestamps
    end

    add_index :countries, :code, unique: true
  end
end