class AddDetailsToRifamaxRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :rifamax_raffles, :details, :text
  end
end
