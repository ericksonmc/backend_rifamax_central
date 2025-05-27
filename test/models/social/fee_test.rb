# == Schema Information
#
# Table name: social_fees
#
#  id               :bigint           not null, primary key
#  admin_profit_fee :float
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
require "test_helper"

class Social::FeeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
