class AddConfirmationToSocialRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :social_raffles, :confirmation, :boolean, default: false
  end
end
