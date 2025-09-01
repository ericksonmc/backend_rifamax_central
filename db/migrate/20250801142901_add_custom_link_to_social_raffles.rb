class AddCustomLinkToSocialRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :social_raffles, :custom_link, :string
  end
end
