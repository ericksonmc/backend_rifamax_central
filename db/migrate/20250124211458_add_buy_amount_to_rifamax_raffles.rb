class AddBuyAmountToRifamaxRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :rifamax_raffles, :buy_amount, :float
  end
end
