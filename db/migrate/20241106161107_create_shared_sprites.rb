class CreateSharedSprites < ActiveRecord::Migration[7.0]
  def change
    create_table :shared_sprites do |t|
      t.string :asset
      t.integer :each_width
      t.integer :each_height
      t.integer :width
      t.integer :height
      t.string :identifier

      t.timestamps
    end
  end
end
