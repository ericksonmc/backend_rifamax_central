class AddDetailsToSocialRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :social_raffles, :dni, :string
    add_column :social_raffles, :rif, :string
    add_column :social_raffles, :bank_register, :string
    add_column :social_raffles, :receipts, :json, default: []
    add_column :social_raffles, :rejecting_details, :text
  end
end
