class AddCombosToSocialRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :social_raffles, :combo, :jsonb, default: {}
  end
end
