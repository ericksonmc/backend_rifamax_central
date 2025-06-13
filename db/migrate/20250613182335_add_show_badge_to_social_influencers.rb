class AddShowBadgeToSocialInfluencers < ActiveRecord::Migration[7.0]
  def change
    add_column :social_influencers, :show_badge, :boolean, default: true
  end
end
