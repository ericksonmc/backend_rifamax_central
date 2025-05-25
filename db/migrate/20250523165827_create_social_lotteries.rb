class CreateSocialLotteries < ActiveRecord::Migration[7.0]
  def change
    create_table :social_lotteries do |t|
      t.string :name
      t.float :profit_fee
      t.string :key_name
      t.string :status

      t.timestamps
    end
  end
end
