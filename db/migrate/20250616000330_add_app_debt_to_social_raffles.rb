class AddAppDebtToSocialRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :social_raffles, :app_debt, :float, default: 0
  end
end
