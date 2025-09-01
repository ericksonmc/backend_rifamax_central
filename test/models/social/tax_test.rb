# == Schema Information
#
# Table name: social_taxes
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE)
#  institute  :string
#  percentage :float            default(0.0)
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class Social::TaxTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
