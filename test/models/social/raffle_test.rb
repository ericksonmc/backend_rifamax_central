# == Schema Information
#
# Table name: social_raffles
#
#  id                   :bigint           not null, primary key
#  ad                   :string
#  app_debt             :float            default(0.0)
#  combos               :jsonb
#  confirmation         :boolean          default(FALSE)
#  draw_type            :string
#  expired_date         :datetime
#  has_winners          :boolean
#  init_date            :datetime
#  limit                :integer
#  money                :string
#  price_unit           :float
#  prizes               :jsonb
#  raffle_type          :string
#  status               :string
#  tickets_count        :integer
#  title                :string
#  winners              :jsonb
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  social_fee_id        :bigint
#  social_influencer_id :bigint           not null
#  social_lottery_id    :bigint
#
# Indexes
#
#  index_social_raffles_on_social_fee_id         (social_fee_id)
#  index_social_raffles_on_social_influencer_id  (social_influencer_id)
#  index_social_raffles_on_social_lottery_id     (social_lottery_id)
#
# Foreign Keys
#
#  fk_rails_...  (social_fee_id => social_fees.id)
#  fk_rails_...  (social_influencer_id => social_influencers.id)
#  fk_rails_...  (social_lottery_id => social_lotteries.id)
#
require "test_helper"

class Social::RaffleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
