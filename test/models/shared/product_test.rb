# == Schema Information
#
# Table name: shared_products
#
#  id         :bigint           not null, primary key
#  color      :string
#  devices    :string           default([]), is an Array
#  image      :string
#  name       :string
#  roles      :string           default([]), is an Array
#  to         :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class Shared::ProductTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
