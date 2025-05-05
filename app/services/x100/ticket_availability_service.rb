module X100
  class TicketAvailabilityService
    class Error < StandardError; end
    class PositionTakenError < Error; end
    class InvalidPositionError < Error; end

    def self.check_availability(raffle, position)
      position = position.to_i
      validate_position(position)
      validate_tickets_availability(raffle, position)

      unless raffle.x100_tickets.exists?(position: position, status: 'available')
        raise PositionTakenError.new("Position #{position} is already taken")
      end

      true
    rescue ActiveRecord::ActiveRecordError => e
      raise Error.new("Availability check failed: #{e.message}")
    end

    def self.check_reserve(raffle, position)
      position = position.to_i
      validate_position(position)
      validate_tickets_availability(raffle, position)

      unless raffle.x100_tickets.exists?(position: position, status: 'reserved')
        raise PositionTakenError.new("Position #{position} is already taken")
      end

      true
    rescue ActiveRecord::ActiveRecordError => e
      raise Error.new("Availability check failed: #{e.message}")
    end
    
    private_class_method

    def self.validate_tickets_availability(raffle, position)
      return if raffle.raffle_type == 'Infinito'
      
      if position > raffle.tickets_count
        raise InvalidPositionError.new("Position is greater than tickets count: #{raffle.tickets_count} tickets to select")
      end
    end

    def self.validate_position(position)
      return if position.positive?

      raise InvalidPositionError.new("Position must be a positive integer")
    end
  end
end