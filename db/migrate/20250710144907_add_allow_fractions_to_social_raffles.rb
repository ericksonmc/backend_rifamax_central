class AddAllowFractionsToSocialRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :social_raffles, :allow_fractions, :boolean, default: false
  end
end
