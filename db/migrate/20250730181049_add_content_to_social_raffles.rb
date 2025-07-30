class AddContentToSocialRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :social_raffles, :content, :text
  end
end
