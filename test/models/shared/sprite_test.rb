# == Schema Information
#
# Table name: shared_sprites
#
#  id          :bigint           not null, primary key
#  asset       :string
#  each_height :integer
#  each_width  :integer
#  height      :integer
#  identifier  :string
#  width       :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "test_helper"

class Shared::SpriteTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
