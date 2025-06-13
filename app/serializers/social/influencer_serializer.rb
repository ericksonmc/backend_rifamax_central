# == Schema Information
#
# Table name: social_influencers
#
#  id             :bigint           not null, primary key
#  content_code   :string
#  lotteries      :integer          default([]), is an Array
#  show_badge     :boolean          default(TRUE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  shared_user_id :bigint           not null
#
# Indexes
#
#  index_social_influencers_on_shared_user_id  (shared_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (shared_user_id => shared_users.id)
#
class Social::InfluencerSerializer < ActiveModel::Serializer
  attributes :id, :influencer_id, :name, :content_code

  def id
    object.shared_user.id
  end

  def name
    object.shared_user.name
  end

  def influencer_id
    object.id
  end
end
