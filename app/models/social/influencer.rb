# == Schema Information
#
# Table name: social_influencers
#
#  id             :bigint           not null, primary key
#  content_code   :string
#  lotteries      :integer          default([]), is an Array
#  show_badge     :boolean          default(TRUE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  shared_user_id :bigint           not null
#
# Indexes
#
#  index_social_influencers_on_shared_user_id  (shared_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (shared_user_id => shared_users.id)
#
class Social::Influencer < ApplicationRecord
  # ------ Foreign Keys Beloging
  belongs_to :shared_user, class_name: 'Shared::User', foreign_key: 'shared_user_id'

  # ------ Associations/relationships between tables
  has_many :social_raffles, class_name: 'Social::Raffle', foreign_key: 'social_influencer_id', dependent: :destroy
  has_many :social_payment_options, class_name: 'Social::PaymentOption', foreign_key: 'social_influencer_id', dependent: :destroy
  has_many :social_payment_methods, class_name: 'Social::PaymentMethod', foreign_key: 'social_influencer_id', dependent: :destroy
  has_many :social_networks, class_name: 'Social::Network', foreign_key: 'social_influencer_id', dependent: :destroy
  has_many :social_badges, class_name: 'Social::Badge', foreign_key: 'social_influencer_id', dependent: :destroy

  # ------ Public internal logic
  def payment_options
    social_payment_options
  end

  def raffles
    social_raffles
  end

  def actives_raffles
    social_raffles.active
  end
end
