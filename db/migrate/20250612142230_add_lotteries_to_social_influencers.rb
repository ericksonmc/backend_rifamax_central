class AddLotteriesToSocialInfluencers < ActiveRecord::Migration[7.0]
  def change
    add_column :social_influencers, :lotteries, :integer, array: true, default: []
  end
end
