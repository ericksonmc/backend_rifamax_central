# frozen_string_literal: true

# == Schema Information
#
# Table name: rifamax_tickets
#
#  id                     :bigint           not null, primary key
#  is_sold                :boolean
#  is_winner              :boolean
#  number                 :integer
#  number_position        :integer
#  uniq_identifier_serial :string
#  wildcard               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  raffle_id              :bigint           not null
#
# Indexes
#
#  index_rifamax_tickets_on_raffle_id  (raffle_id)
#
# Foreign Keys
#
#  fk_rails_...  (raffle_id => rifamax_raffles.id)
#
module Rifamax
  class TicketSerializer < ActiveModel::Serializer
    attributes :id, :is_sold, :is_winner, :wildcard, :number_position, :uniq_identifier_serial

    def uniq_identifier_serial
      object.uniq_identifier_serial[0..5] + object.uniq_identifier_serial[-5..-1]
    end
  end
end
