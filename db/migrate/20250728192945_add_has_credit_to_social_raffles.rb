class AddHasCreditToSocialRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :social_raffles, :has_credit, :boolean, default: false
  end
end
