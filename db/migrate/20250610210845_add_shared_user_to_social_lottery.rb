class AddSharedUserToSocialLottery < ActiveRecord::Migration[7.0]
  def change
    add_reference :social_lotteries, :shared_user, null: false, foreign_key: true
  end
end
