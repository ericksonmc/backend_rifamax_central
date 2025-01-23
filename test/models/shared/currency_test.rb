# == Schema Information
#
# Table name: shared_currencies
#
#  id         :bigint           not null, primary key
#  currency   :string
#  label      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class Shared::CurrencyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
