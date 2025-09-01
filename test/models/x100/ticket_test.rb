# frozen_string_literal: true

# == Schema Information
#
# Table name: x100_tickets
#
#  id             :bigint           not null, primary key
#  apart_ends     :datetime
#  aparted_by     :integer
#  money          :string
#  position       :integer
#  price          :float
#  serial         :string
#  status         :string           default("available")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  x100_client_id :bigint
#  x100_raffle_id :bigint           not null
#
# Indexes
#
#  index_x100_tickets_on_x100_client_id  (x100_client_id)
#  index_x100_tickets_on_x100_raffle_id  (x100_raffle_id)
#
# Foreign Keys
#
#  fk_rails_...  (x100_client_id => x100_clients.id)
#  fk_rails_...  (x100_raffle_id => x100_raffles.id)
#
require 'test_helper'

module X100
  class TicketTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
