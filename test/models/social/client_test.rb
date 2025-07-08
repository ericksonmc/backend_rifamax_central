# == Schema Information
#
# Table name: social_clients
#
#  id         :bigint           not null, primary key
#  address    :string
#  country    :string
#  dni        :string
#  email      :string
#  name       :string
#  phone      :string
#  province   :string
#  zip_code   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class Social::ClientTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
