class AddLotteryPaymentOptionsToSocialRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :social_raffles, :is_lottery_payed, :boolean, default: false
    add_column :social_raffles, :lottery_payment, :jsonb, default: {}
  end
end
