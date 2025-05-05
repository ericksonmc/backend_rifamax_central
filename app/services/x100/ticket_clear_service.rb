module X100
  class TicketClearService
    class Error < StandardError; end
    class RaffleNotFoundError < Error; end
    class StateTransitionError < Error; end
    class InvalidPositionsError < Error; end

    def self.clear(raffle_id, positions)
      validate_positions(positions)
      raffle = X100::Raffle.find(raffle_id)
      
      ActiveRecord::Base.transaction do
        positions.each do |position|
          ticket = raffle.x100_tickets.reserved.find_by(position: position)
          
          if ticket
            begin
              ticket.x100_client_id = nil
              ticket.aparted_by = nil
              ticket.apart_ends = nil
              ticket.turn_available!
              ticket.save!
            rescue AASM::InvalidTransition => e
              raise StateTransitionError.new("Cannot transition ticket #{position}: #{e.message}")
            end
          end
        end
      end
    rescue ActiveRecord::RecordNotFound
      raise RaffleNotFoundError.new("Raffle not found with ID: #{raffle_id}")
    rescue ActiveRecord::ActiveRecordError => e
      raise Error.new("Clear operation failed: #{e.message}")
    end

    private_class_method

    def self.validate_positions(positions)
      return if positions.is_a?(Array) && positions.all? { |p| p.to_i.positive? }

      raise InvalidPositionsError.new("Positions must be an array of positive integers")
    end
  end
end