# == Schema Information
#
# Table name: social_contexts
#
#  id         :bigint           not null, primary key
#  context    :jsonb
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class Social::ContextTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
