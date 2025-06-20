class CreateSocialTaxes < ActiveRecord::Migration[7.0]
  def change
    create_table :social_taxes do |t|
      t.string :title
      t.float :percentage, default: 0.0
      t.boolean :active, default: true
      t.string :institute

      t.timestamps
    end
  end
end
