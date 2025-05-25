# == Schema Information
#
# Table name: social_lotteries
#
#  id         :bigint           not null, primary key
#  key_name   :string
#  name       :string
#  profit_fee :float
#  status     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class Social::LotteryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
