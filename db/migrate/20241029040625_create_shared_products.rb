class CreateSharedProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :shared_products do |t|
      t.string :name
      t.string :image
      t.string :color
      t.string :to
      t.string :roles, array: true, default: []
      t.string :devices, array: true, default: []

      t.timestamps
    end
  end
end
