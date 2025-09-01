class AddDniToSocialClients < ActiveRecord::Migration[7.0]
  def change
    add_column :social_clients, :dni, :string
  end
end
