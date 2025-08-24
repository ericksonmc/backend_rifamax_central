# == Schema Information
#
# Table name: social_payment_methods
#
#  id                   :bigint           not null, primary key
#  amount               :float
#  capture              :string
#  currency             :string
#  details              :jsonb
#  email_send           :boolean          default(FALSE)
#  fly_amounts          :float            default([]), is an Array
#  fraction_debt        :float            default(0.0)
#  fractions            :integer          default(1)
#  has_fly_amount       :boolean          default(FALSE)
#  is_fractionated      :boolean          default(FALSE)
#  payment              :string
#  payment_option       :integer          default(0)
#  payment_rate         :float
#  quantity_requested   :integer
#  serial               :string
#  status               :string           default("active")
#  tickets              :integer          default([]), is an Array
#  whatsapp_send        :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  fraction_id          :bigint
#  social_client_id     :bigint           not null
#  social_influencer_id :bigint
#  social_raffle_id     :bigint
#
# Indexes
#
#  index_social_payment_methods_on_serial                (serial) UNIQUE
#  index_social_payment_methods_on_social_client_id      (social_client_id)
#  index_social_payment_methods_on_social_influencer_id  (social_influencer_id)
#  index_social_payment_methods_on_social_raffle_id      (social_raffle_id)
#
# Foreign Keys
#
#  fk_rails_...  (social_client_id => social_clients.id)
#  fk_rails_...  (social_influencer_id => social_influencers.id)
#  fk_rails_...  (social_raffle_id => social_raffles.id)
#
class Social::PaymentMethodSerializer < ActiveModel::Serializer
  attributes :id, :payment, :amount, :payment_option, :serial, :currency, :status, :details, :client, :tickets, :raffle, :has_fly_amount, :capture, :tickets_count, :fly_amounts, :fractions, :fraction_debt, :is_fractionated, :payment_rate, :created_at

  def client
    object.social_client
  end

  def tickets_count
    object.social_raffle.tickets_count
  end
  
  def raffle
    object.social_raffle.title
  end

  def capture 
    return nil if object.capture.nil?
    ENV['url_base'] + object.capture.url
  end

  def created_at
    object.created_at.strftime('%d/%m/%Y')
  end
end
