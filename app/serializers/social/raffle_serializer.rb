class Social::RaffleSerializer < ActiveModel::Serializer
  attributes :id, :ad, :title, :combos, :draw_type, :expired_date, :has_winners, :init_date, :limit, :money, :price_unit, :prizes, :raffle_type, :social_influencer_id, :status, :tickets_count, :winners, :created_at, :updated_at

  def ad
    object.ad.url = "#{ENV['URL_BASE']}/#{object.ad.url}" if object.ad.present?
  end
end
