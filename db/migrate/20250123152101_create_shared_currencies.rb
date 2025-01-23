class CreateSharedCurrencies < ActiveRecord::Migration[7.0]
  def change
    create_table :shared_currencies do |t|
      t.string :currency
      t.string :label

      t.timestamps
    end
  end
end
