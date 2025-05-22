# frozen_string_literal: true

# == Schema Information
#
# Table name: shared_exchanges
#
#  id               :bigint           not null, primary key
#  automatic        :boolean
#  mainstream_money :string
#  value_bs         :float
#  value_cop        :float
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
# 
module Shared
  class Exchange < ApplicationRecord
    has_many :x100_orders, class_name: 'X100::Order', foreign_key: 'shared_exchange_id'
    # has_many :social_orders, class_name: 'Social::Order', foreign_key: 'shared_exchange_id'
    has_many :social_payment_methods, class_name: 'Social::PaymentMethod', foreign_key: 'shared_exchange_id'

    include HTTParty
    require 'nokogiri'
    require 'open-uri'

    after_create :change_exchange

    def self.generate_exchange
      Shared::Exchange.create(automatic: true, mainstream_money: 'USD')
    end

    def self.get_cop
      fx = Currencyapi::Endpoints.new(apikey: ENV["currency_api_key"])

      string = fx.latest('USD', 'COP')

      json_string = string.gsub(/\A"|"\z/, '').gsub('\\"', '"')

      json_object = JSON.parse(json_string)

      value = json_object['data']['COP']['value']

      value.round(2)
    end

    def self.get_bsd
      url = 'https://www.bcv.org.ve'

      agent = Mechanize.new

      agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      html = agent.get(url).body

      doc = Nokogiri::HTML(html)

      dolar_value = doc.at_css('#dolar strong').content.strip

      dolar_value.gsub(',', '.').to_f.round(2)
    end

    def change_exchange
      return unless automatic

      $redis.setex("exchange_change", 86400, 'change_exchange')

      self.value_bs = Shared::Exchange.get_bsd
      self.value_cop = Shared::Exchange.get_cop
      self.mainstream_money = 'USD'
      save
    end
  end
end
