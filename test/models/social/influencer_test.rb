# == Schema Information
#
# Table name: social_influencers
#
#  id             :bigint           not null, primary key
#  content_code   :string
#  lotteries      :integer          default([]), is an Array
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
require "test_helper"

class Social::InfluencerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
