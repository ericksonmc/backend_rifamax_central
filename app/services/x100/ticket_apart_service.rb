module X100
  class TicketApartService
    class RaffleNotFoundError < StandardError; end
    class TicketNotFoundError < StandardError; end
    class ClientNotFoundError < StandardError; end
    class InvalidPositionError < StandardError; end
    class ExternalServiceError < StandardError; end
    class TicketReservingError < StandardError; end
    class IntegratorNotFoundError < StandardError; end

    def self.reserve(raffle_id, position, user)
      @raffle = X100::Raffle.find(raffle_id)

      raise RaffleNotFoundError.new "Raffle not found" if @raffle.nil? 

      verify_valid_position(@raffle, position)
      verify_ticket_status(@raffle, position)

      ActiveRecord::Base.transaction do 
        ticket = X100::Ticket.lock('FOR UPDATE NOWAIT').find_by(x100_raffle_id: @raffle.id, position: position)
  
        ticket.apart!
        ticket.aparted_by = user.id
        ticket.apart_ends = DateTime.now + 5.minutes
        ticket.save!
        $redis.setex("ticket_#{ticket.id}", 300, ticket.id)

        X100::BroadcastingService.refresh
      end
      
    rescue => e
      raise TicketReservingError, e.message 
    end

    def self.reserve_via_integration(raffle_id, position, integrator_id, integrator_type, money)
      @raffle = X100::Raffle.find(raffle_id)
      @ticket = X100::Ticket.find_by(x100_raffle_id: raffle_id, position: position)

      raise RaffleNotFoundError.new "Raffle not found" if @raffle.nil? 
      raise TicketNotFoundError.new "Ticket not found" if @ticket.nil? 
      
      verify_valid_position(@raffle, position)
      verify_ticket_status(@raffle, position)
      verify_integrator_connection(integrator_id, integrator_type, money)

      @client = X100::Client.find_by(integrator_id: integrator_id, integrator_type: integrator_type)
      
      raise ClientNotFoundError.new "Client not found" if @client.nil?
      
      ActiveRecord::Base.transaction do 
        ticket = X100::Ticket.lock('FOR UPDATE NOWAIT').find_by(x100_raffle_id: @raffle.id, position: position)
  
        ticket.x100_client_id = @client.id
        ticket.apart!
        ticket.aparted_by = integrator_id
        ticket.apart_ends = DateTime.now + 5.minutes
        ticket.save!
        $redis.setex("ticket_#{ticket.id}", 300, ticket.id)

        @ticket.apart_ends = DateTime.now + 5.minutes
        @ticket.aparted_by = integrator_id
        @ticket.status = 'reserved'

        X100::BroadcastingService.refresh
      end

      return @ticket
    
    rescue => e
      raise TicketReservingError, e.message 
    end

    private_class_method

    def self.verify_ticket_status(raffle, position)
      X100::TicketAvailabilityService.check_availability(raffle, position)
    end

    def self.verify_integrator_connection(integrator_id, integrator_type, money)
      integrators_url = {
        'CDA' => "#{ENV["cda_url_base"]}/wallets_rifas?player_id=#{integrator_id}&currency=#{money}"
      }

      url = "#{ENV["cda_url_base"]}/wallets_rifas?player_id=#{713}&currency=#{money}"
      raise IntegratorNotFoundError.new "Integrator not found" unless url

      response = HTTParty.get(url)

      error = {
        message: "Integrator #{integrator_type} is throwing error",
        body: JSON.parse(response.body),
        code: response.code
      }

      raise ExternalServiceError.new(
        JSON.parse(error)  
      ) unless response.code == 200

      response
    end

    def self.verify_valid_position(raffle, position)
      ticket_existant = X100::Ticket.exists?(x100_raffle_id: raffle.id, position: position)
    
      return if ticket_existant

      raise InvalidPositionError.new "Ticket position: #{position} is not valid"
    end
  end
end