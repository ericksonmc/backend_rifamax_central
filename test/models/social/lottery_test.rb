# == Schema Information
#
# Table name: social_lotteries
#
#  id             :bigint           not null, primary key
#  key_name       :string
#  name           :string
#  profit_fee     :float
#  status         :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  shared_user_id :bigint           not null
#
# Indexes
#
#  index_social_lotteries_on_shared_user_id  (shared_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (shared_user_id => shared_users.id)
#
require "test_helper"

class Social::LotteryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
