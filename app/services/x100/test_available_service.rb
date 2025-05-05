module X100
  class TestAvailableService < ApplicationController
    def self.available(raffle_id, positions)
      positions.each do |position|
        @x100_ticket = X100::Ticket.find_by(x100_raffle_id: raffle_id, position: position)
        if @x100_ticket.nil?
          render_not_found("Ticket with position: #{position} can't be apart")
        elsif !@x100_ticket.available?
          @x100_ticket.update(x100_client_id: nil)
          return true
        else
          return false
        end
      end

      @tickets = X100::Ticket.all_sold_tickets
      @raffles = X100::Raffle.current_progress_of_actives

      ActionCable.server.broadcast('x100_raffles', @raffles)
      ActionCable.server.broadcast('x100_tickets', @tickets)
    end
  end
end