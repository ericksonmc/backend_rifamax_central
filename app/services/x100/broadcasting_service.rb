module X100
  class BroadcastingService
    def self.refresh
      tickets = X100::Ticket.all_sold_tickets
      raffles = X100::Raffle.current_progress_of_actives
    
      ActionCable.server.broadcast('x100_raffles', @raffles)
      ActionCable.server.broadcast('x100_tickets', @tickets)
    end

    def self.reload
      url = ENV['url_base']
      HTTParty.post("#{url}/x100/tickets/refresh")
    end
  end
end