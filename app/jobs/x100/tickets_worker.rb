require 'sidekiq'

module X100
  class TicketsWorker
    include Sidekiq::Job

    sidekiq_options queue: :verify_x100

    def perform(ticket_id)
      # ticket = X100::Ticket.find(ticket_id)

      # if ticket.reserved?
      #   ticket.turn_available!
      # end
      
      # url = 'https://api.rifamax.app/x100/tickets/refresh'

      # HTTParty.post(url)

      puts "ticket: #{ticket_id}"
    end
  end
end
