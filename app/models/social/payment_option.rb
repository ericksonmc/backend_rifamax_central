# == Schema Information
#
# Table name: social_payment_options
#
#  id                   :bigint           not null, primary key
#  country              :string
#  details              :jsonb
#  name                 :string
#  rate                 :float            default(1.0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  social_influencer_id :bigint           not null
#
# Indexes
#
#  index_social_payment_options_on_social_influencer_id  (social_influencer_id)
#
# Foreign Keys
#
#  fk_rails_...  (social_influencer_id => social_influencers.id)
#
class Social::PaymentOption < ApplicationRecord
  self.table_name = 'social_payment_options'

  # ------ Foreign Keys Beloging
  belongs_to :social_influencer, class_name: 'Social::Influencer', foreign_key: 'social_influencer_id'

  # ------ Validations
  validates :name,
            presence: true
            # inclusion: {
            #   in: ['Pago Móvil', 'Paypal', 'Zelle', 'Stripe', 'Western Union']
            # }
  
  validates :country,
            presence: true
            # inclusion: {
            #   in: ['Venezuela', 'Estados Unidos']
            # }
end
