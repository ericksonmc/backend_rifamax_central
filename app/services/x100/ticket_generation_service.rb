module X100
  class TicketGenerationService
    class Error < StandardError; end
    
    def self.generate(raffle)
      return if infinity?(raffle)

      verify_if_tickets_exists(raffle)

      tickets = build_tickets_array(raffle)
      create_tickets(tickets)
    end

    private_class_method

    def self.infinity?(raffle)
      raffle.raffle_type == 'Infinito'
    end

    def self.build_tickets_array(raffle)
      (1..raffle.tickets_count).map do |position|
        {
          position: position,
          x100_raffle_id: raffle.id,
          serial: SecureRandom.uuid
        }
      end
    end

    def self.verify_if_tickets_exists(raffle)
      return if raffle.tickets_count.zero?

      existing_tickets = X100::Ticket.where(x100_raffle_id: raffle.id)

      raise Error, "Can't generate tickets, this raffle has tickets generated" if existing_tickets.any?
    end

    def self.create_tickets(tickets)
      result = X100::Ticket.insert_all(tickets)
      raise Error, "Failed to create tickets" if result.empty?
      result
    rescue ActiveRecord::ActiveRecordError => e
      raise Error, "Database error: #{e.message}"
    end
  end
end