# == Schema Information
#
# Table name: social_payment_methods
#
#  id                   :bigint           not null, primary key
#  amount               :float
#  currency             :string
#  details              :jsonb
#  email_send           :boolean          default(FALSE)
#  payment              :string
#  quantity_requested   :integer
#  status               :string
#  whatsapp_send        :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  shared_exchange_id   :bigint
#  social_client_id     :bigint           not null
#  social_influencer_id :bigint
#  social_raffle_id     :bigint
#
# Indexes
#
#  index_social_payment_methods_on_shared_exchange_id    (shared_exchange_id)
#  index_social_payment_methods_on_social_client_id      (social_client_id)
#  index_social_payment_methods_on_social_influencer_id  (social_influencer_id)
#  index_social_payment_methods_on_social_raffle_id      (social_raffle_id)
#
# Foreign Keys
#
#  fk_rails_...  (shared_exchange_id => shared_exchanges.id)
#  fk_rails_...  (social_client_id => social_clients.id)
#  fk_rails_...  (social_influencer_id => social_influencers.id)
#  fk_rails_...  (social_raffle_id => social_raffles.id)
#
class Social::PaymentMethodSerializer < ActiveModel::Serializer
  attributes :id, :payment, :amount, :currency, :status, :details, :client, :raffle, :created_at

  def client
    object.social_client
  end

  def raffle
    object.social_raffle.title
  end

  def created_at
    object.created_at.strftime('%d/%m/%Y')
  end
end
