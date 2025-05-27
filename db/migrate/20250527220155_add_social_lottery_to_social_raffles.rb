class AddSocialLotteryToSocialRaffles < ActiveRecord::Migration[7.0]
  def change
    add_reference :social_raffles, :social_lottery, null: true, foreign_key: true
  end
end
