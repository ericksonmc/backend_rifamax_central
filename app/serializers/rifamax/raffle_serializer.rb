# frozen_string_literal: true

# == Schema Information
#
# Table name: rifamax_raffles
#
#  id                     :bigint           not null, primary key
#  admin_status           :integer
#  buy_amount             :float
#  buy_currency           :string
#  currency               :string
#  details                :text
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
module Rifamax
  class RaffleSerializer < ActiveModel::Serializer
    attributes :id, :admin_status, :currency, :expired_date, :init_date, :lotery, :numbers, :price, :buy_currency, :prizes, :security, :buy_amount, :sell_status, :title, :uniq_identifier_serial

    belongs_to :user, serializer: Shared::UserSerializer
    belongs_to :seller, serializer: Shared::UserSerializer

    def security
      object.security['wildcard']
    end
  end
end
