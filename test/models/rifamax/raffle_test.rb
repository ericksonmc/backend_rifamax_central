# == Schema Information
#
# Table name: rifamax_raffles
#
#  id                     :bigint           not null, primary key
#  admin_status           :integer
#  buy_amount             :float
#  currency               :string
#  expired_date           :date
#  init_date              :date
#  lotery                 :string
#  numbers                :integer
#  payment_info           :jsonb
#  price                  :float
#  prizes                 :jsonb            is an Array
#  security               :jsonb
#  sell_status            :integer
#  title                  :string
#  uniq_identifier_serial :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  seller_id              :bigint           not null
#  user_id                :bigint           not null
#
# Indexes
#
#  index_rifamax_raffles_on_seller_id  (seller_id)
#  index_rifamax_raffles_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (seller_id => shared_users.id)
#  fk_rails_...  (user_id => shared_users.id)
#
require "test_helper"

class Rifamax::RaffleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
