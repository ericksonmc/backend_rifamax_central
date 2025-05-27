# == Schema Information
#
# Table name: social_fees
#
#  id               :bigint           not null, primary key
#  admin_profit_fee :float
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class Social::Fee < ApplicationRecord
  has_many :social_raffles, class_name: 'Social::Raffle', foreign_key: 'social_fee_id', dependent: :destroy

  validates :admin_profit_fee,
            presence: true
end
