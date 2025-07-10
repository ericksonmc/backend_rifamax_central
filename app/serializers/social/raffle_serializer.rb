# == Schema Information
#
# Table name: social_raffles
#
#  id                   :bigint           not null, primary key
#  ad                   :string
#  allow_fractions      :boolean          default(FALSE)
#  app_debt             :float            default(0.0)
#  bank_register        :string
#  combos               :jsonb
#  confirmation         :boolean          default(FALSE)
#  dni                  :string
#  draw_type            :string
#  expired_date         :datetime
#  has_winners          :boolean
#  init_date            :datetime
#  limit                :integer
#  money                :string
#  price_unit           :float
#  prizes               :jsonb
#  raffle_type          :string
#  receipts             :json
#  rejecting_details    :text
#  rif                  :string
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
class Social::RaffleSerializer < ActiveModel::Serializer
  attributes :id, :ad, :dni, :rif, :bank_register, :allow_fractions, :receipts, :title, :combos, :draw_type, :lottery, :confirmation, :original_app_debt, :expired_date, :has_winners, :init_date, :limit, :money, :price_unit, :prizes, :raffle_type, :social_influencer_id, :status, :tickets_count, :app_debt, :debt_percentage, :tickets_available, :winners, :created_at, :updated_at

  def ad
    return unless object.ad.present?

    object.ad.as_json.merge(
      'url' => "#{ENV['url_base']}/#{object.ad.url}"
    )
  end

  def lottery
    object.social_lottery.name
  end


  def dni
    return unless object.dni.present?

    object.dni.as_json.merge(
      'url' => "#{ENV['url_base']}/#{object.dni.url}"
    )
  end

  def rif
    return unless object.rif.present?
    object.rif.as_json.merge(
      'url' => "#{ENV['url_base']}/#{object.rif.url}"
    )
  end

  def bank_register
    return unless object.bank_register.present?
    object.bank_register.as_json.merge(
      'url' => "#{ENV['url_base']}/#{object.bank_register.url}"
    )
  end

  def receipts
    return unless object.receipts.present?
    object.receipts.map do |receipt|
      receipt.as_json.merge(
        'url' => "#{ENV['url_base']}/#{receipt.url}"
      )
    end
  end

  def original_app_debt
    (object.tickets_count.to_f * object.price_unit.to_f * 0.05).round(2)
  end
  
  def debt_percentage
    orig_debt = original_app_debt
    curr_debt = object.app_debt.to_f
  
    return 0 if orig_debt <= 0 || curr_debt <= 0
    return 100 if curr_debt >= orig_debt
  
    (((orig_debt - curr_debt) / orig_debt) * 100).round(2)
  end
  
  def tickets_available
    sold = $redis.get("social_sold_serie:#{object.id}")
    sold_array = begin
      JSON.parse(sold) if sold.present?
    rescue JSON::ParserError
      []
    end
    sold_count = sold_array.is_a?(Array) ? sold_array.length : object.tickets_count
    object.tickets_count - sold_count
  end
end
