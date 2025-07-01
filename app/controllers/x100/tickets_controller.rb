# frozen_string_literal: true

module X100
  class TicketsController < ApplicationController
    before_action :authorize_request, except: [:refresh]
    before_action :fetch_tickets, only: [:index]
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    before_action :unable_access_when_is_not_integration, only: %i[refund clear apart_integrator]

    def index
      @tickets = X100::Ticket.all_sold_tickets

      render json: @tickets, status: :ok
    end

    def show
      @x100_ticket = X100::Ticket.sold_tickets(params[:id]).first

      if @x100_ticket.nil?
        render json: { message: "Raffle with ID: #{params[:id]} not found" }, status: :not_found
      else
        render json: @x100_ticket, status: :ok
      end
    end

    def sell_series
      ActiveRecord::Base.transaction do 
        client_id = sell_series_ticket_params[:client_id]
        integrator = sell_series_ticket_params[:integrator]
        raffle_id = sell_series_ticket_params[:raffle_id]
        quantity = sell_series_ticket_params[:quantity]
        currency = sell_series_ticket_params[:money]

        @raffle = X100::Raffle.find(raffle_id)
        # @client = X100::Client.find(client_id)
        @client_integrator = X100::Client.find_by(
          integrator_id: client_id, 
          integrator_type: integrator
        )

        @result = @raffle.sell_series(
          quantity,
          currency,
          client_id,
          integrator,
          @client_integrator.id
        )

        render json: @result, status: :ok
      end
    end

    def sell
      money = sell_x100_ticket_params[:money]
      positions = sell_x100_ticket_params[:positions]
      client_id = sell_x100_ticket_params[:x100_client_id]
      integrator = sell_x100_ticket_params[:integrator]
      raffle = X100::Raffle.find(sell_x100_ticket_params[:x100_raffle_id])
    
      if positions.blank?
        return parameter_require_error('Positions parameter is required')
      end

      record_not_found unless raffle
    
      order = if integrator.nil? 
        X100::TicketSellingService.sell(
          money: money,
          raffle: raffle,
          products: positions,
          user: @current_user,
          client_id: client_id,
        ) 
      else
        X100::TicketSellingService.sell_via_integrator(
          money: money,
          raffle: raffle,
          products: positions,
          user: @current_user,
          integrator_id: client_id,
          integrator_type: integrator,
        )
      end
    
      render json: {
        success: true,
        message: 'Tickets successfully purchased',
        details: {
          order: order,
          amount: order&.amount,
          currency: money,
          raffle_title: raffle.title,
          purchased_positions: positions,
          purchased_at: Time.current.iso8601
        }
      }, status: :ok
    rescue X100::TicketSellingService::TicketSellingError, StandardError => e
      render_error_response(e.message, :unprocessable_entity)
    end

    def clear
      client = X100::Client.find_by(clear_params)

      if client.nil?
        render json: { message: 'Client not found' }, status: :not_found
      else
        ActiveRecord::Base.transaction do
          @x100_tickets = X100::Ticket.where(x100_client_id: client.id, status: 'reserved')
          if @x100_tickets.empty?
            raise ActiveRecord::Rollback, 'Tickets not found'
          end
          @x100_tickets.update_all(status: 'available', x100_client_id: nil)
          X100::BroadcastingService.refresh
          render json: { message: 'Tickets cleared!', is_cleared: true }, status: :ok
        rescue StandardError => e
          render json: { message: "Tickets can't be cleared!", is_cleared: false, error: e }, status: :unprocessable_entity
        end
      end
    end

    def apart_integrator
      money = apart_integrator_params[:money]
      position = apart_integrator_params[:position]
      raffle_id = apart_integrator_params[:x100_raffle_id]
      integrator_id = apart_integrator_params[:integrator_id]
      integrator_type = apart_integrator_params[:integrator_type]

      ticket = X100::Ticket.exists?(
        position: position,
        x100_raffle_id: raffle_id
      )

      return render_not_found("Ticket with position: #{position} can't be apart") unless ticket

      ticket_result = X100::TicketApartService.reserve_via_integration(
        raffle_id,
        position,
        integrator_id,
        integrator_type,
        money
      )

      render json: {
        message: 'Ticket was reserved successfully!',
        ticket: ticket_result

      }

      rescue X100::TicketApartService::TicketReservingError, StandardError => e
        render_error_response(e.message, 401)
    end

    def refresh
      X100::BroadcastingService.refresh

      render json: { message: 'Ok!' }, status: :ok
    end

    def refund
      @x100_client = X100::Client.find_by(integrator_id: refund_params[:integrator_id], integrator_type: refund_params[:integrator_type])
      @x100_order = X100::Order.find_by(serial: refund_params[:serial])

      if @x100_order.nil?
        render json: { message: 'Order not found' }, status: :not_found
      else
        if @x100_order.status == 'refunded'
          render json: { message: 'Order already refunded', order: @x100_order }, status: :unprocessable_entity
        else
          if @x100_order.integrator_credit_job
            @x100_order.refund_order!
            X100::BroadcastingService.refresh
            render json: { message: 'Tickets refunded!', order: @x100_order }, status: :ok
          else
            render json: { message: 'Order can not be refunded', order: @x100_order }, status: :unprocessable_entity
          end
        end
      end
    end

    def buy_infinite
      raffle = X100::Raffle.find(buy_infinite_params[:x100_raffle_id])
      quantity = buy_infinite_params[:quantity].to_i
      money = buy_infinite_params[:money]
      client_id = buy_infinite_params[:x100_client_id]
      integrator_id = buy_infinite_params[:integrator_id]
      integrator_type = buy_infinite_params[:integrator_type]

      order = raffle.sell_infinity(quantity, money, client_id, integrator_id, integrator_type)

      if raffle.nil?
        render json: { errors: ["Raffle not found or doesn't exist"] }, status: :not_found
      else
        render json: order, status: :ok
      end
    rescue => e
      Rails.logger.debug "Exception in buy_infinite action: #{e.message}"
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def combo
      @quantity = combos_params[:quantity].to_i
      @tickets_combo = X100::Raffle.find(combos_params[:x100_raffle_id]).select_combos(@quantity)
      X100::BroadcastingService.refresh
      render json: { message: 'Tickets already selected!', ticket: @tickets_combo }, status: :ok
    rescue StandardError => e
      render json: { message: 'Oops! An error has been occurred', error: e }, status: :unprocessable_entity
    end

    def apart
      @x100_ticket = X100::Ticket.find_by(find_raffles_by_params)

      if @x100_ticket.nil?
        render_not_found("Ticket with position: #{find_raffles_by_params[:position]} can't be apart")
      elsif @x100_ticket.available?
        return raffle_is_closed_error if @x100_ticket.status == 'Cerrada'
        
        X100::Ticket.apart_ticket(@x100_ticket.id, @current_user.id)
        X100::BroadcastingService.refresh
        render json: { message: 'Ticket aparted', ticket: @x100_ticket }, status: :ok
      else
        render json: { message: "Ticket with position: #{find_raffles_by_params[:position]} can't be apart" },
               status: :unprocessable_entity
      end
    end

    def available
      @x100_ticket = X100::Ticket.find_by(find_raffles_by_params)

      if @x100_ticket.nil?
        render_not_found("Ticket with position: #{find_raffles_by_params[:position]} can't be apart")
      elsif @x100_ticket.reserved?
        return raffle_is_closed_error if @x100_ticket.status == 'Cerrada'

        X100::Ticket.find(@x100_ticket.id).turn_available!
        @tickets = X100::Ticket.all_sold_tickets
        @raffles = X100::Raffle.current_progress_of_actives
        @x100_ticket.status = 'available'

        ActionCable.server.broadcast('x100_raffles', @raffles)
        ActionCable.server.broadcast('x100_tickets', @tickets)
        render json: { message: 'Ticket returns to available', ticket: @x100_ticket }, status: :ok
      else
        render json: { message: "Ticket with position: #{find_raffles_by_params[:position]} can't be available" },
               status: :unprocessable_entity
      end
    end

    private

    def validates_positions(positions = [])
      result = []

      positions.each do |position|
        @x100_ticket = find_reserved_ticket(position)

        return 'Error' if @x100_ticket.nil?

        result << position
      end

      result
    end
    
    def find_reserved_ticket(position)
      X100::Ticket.find_by(x100_raffle_id: sell_x100_ticket_params[:x100_raffle_id], position: position,
      status: 'reserved')
    end

    def unable_access_when_is_not_integration
      unless @current_user.is_integration
        render json: { message: "This user is not allowed to perform this action" }, status: :forbidden
      end
    end
    
    def render_ticket_not_sold(position)
      render json: { message: "Tickets with position: #{position} can't be sold" }, status: :unprocessable_entity
    end
    
    def refund_params
      params.require(:x100_ticket).permit(:serial, :integrator_id, :integrator_type)
    end 

    def ticket_params
      sell_x100_ticket_params.slice(:x100_client_id, :x100_raffle_id, :price, :money)
    end

    def apart_integrator_params
      params.require(:ticket).permit(:x100_raffle_id, :position, :integrator_id, :integrator_type, :money)
    end

    def find_raffles_by_params
      params.require(:x100_ticket).permit(:x100_raffle_id, :position)
    end

    def render_not_found(message)
      render json: { message: message ? "Resource can't be found" : message }, status: :not_found
    end

    def sell_series_ticket_params
      params.require(:series_ticket).permit(:raffle_id, :client_id, :integrator, :money, :quantity)
    end

    def process_ticket_sale(raffle, success_sold)
      quantity = success_sold.length
      money = sell_x100_ticket_params[:money]

      if integrator_present?
        process_integrator_sale(raffle, success_sold, quantity, money)
      else
        process_regular_sale(raffle, success_sold, quantity, money)
      end
      
      update_tickets_status(raffle, success_sold, money)
      X100::BroadcastingService.refresh
    end

    def process_integrator_sale(raffle, success_sold, quantity, money)
      raise ActiveRecord::Rollback, 'Player ID required' unless sell_x100_ticket_params[:player_id]

      integrator_client = find_integrator_client
      @orders = create_order(raffle, success_sold, quantity, money, integrator_client)
      
      unless @orders.sell_integrator
        raise ActiveRecord::Rollback, 'Integrator API failed to sell ticket'
      end
    end

    def process_regular_sale(raffle, success_sold, quantity, money)
      @orders = create_order(raffle, success_sold, quantity, money)
      @orders.save!
    end

    def create_order(raffle, success_sold, quantity, money, client = nil)
      X100::Order.new(
        products: success_sold,
        amount: raffle.calculate_final_amount(quantity, money),
        serial: generate_order_serial,
        ordered_at: DateTime.current,
        money: money,
        shared_user_id: @current_user.id,
        x100_client_id: client&.id || sell_x100_ticket_params[:x100_client_id],
        x100_raffle_id: raffle.id,
        integrator_player_id: sell_x100_ticket_params[:player_id],
        integrator: sell_x100_ticket_params[:integrator],
        shared_exchange_id: Shared::Exchange.last.id
      )
    end

    def update_tickets_status(raffle, positions, money)
      X100::Ticket.where(position: positions, x100_raffle_id: raffle.id).update_all(
        price: raffle.price_unit,
        money: money,
        status: 'sold',
        x100_client_id: integrator_client&.id || sell_x100_ticket_params[:x100_client_id]
      )
    end

    def validate_positions(positions)
      # Implement actual position validation logic here
      # Should return array of valid positions
      positions.select { |pos| valid_position?(pos) }
    end

    def integrator_present?
      sell_x100_ticket_params[:integrator].present?
    end

    def find_integrator_client
      X100::Client.find_by(
        integrator_id: sell_x100_ticket_params[:x100_client_id],
        integrator_type: sell_x100_ticket_params[:integrator]
      ) || raise(ActiveRecord::Rollback, 'Integrator client not found')
    end

    def generate_order_serial
      "ORD-#{SecureRandom.hex(8).upcase}"
    end

    def success_response(success_sold)
      {
        message: 'Tickets sold',
        tickets: X100::Ticket.where(position: success_sold, x100_raffle_id: sell_x100_ticket_params[:x100_raffle_id]),
        order: @orders.serial
      }
    end

    def render_error_response(message, status)
      error = begin
        parsed = JSON.parse(message)
        parsed.is_a?(Hash) ? parsed : { error: parsed }
      rescue JSON::ParserError
        { error: message }
      end

      render json: error, status: status
    end


    def parameter_require_error(message = 'Missing required parameters')
      render json: { error: message }, status: :unprocessable_entity
    end

    def render_ticket_not_sold(positions)
      render json: { error: "Invalid positions: #{positions.join(', ')}" }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end

    def record_not_found
      render json: { error: 'Raffle not found' }, status: :not_found
    end

    def sell_x100_ticket_params
      params.require(:x100_ticket).permit(:x100_raffle_id, :x100_client_id, :money, :integrator, :player_id,
                                          positions: [])
    end

    def clear_params
      params.require(:client).permit(:integrator_id, :integrator_type)
    end

    def combos_params
      params.require(:combo).permit(:x100_raffle_id, :quantity)
    end

    def buy_infinite_params
      params.require(:raffle).permit(:x100_raffle_id, :quantity, :money, :x100_client_id, :integrator_id, :integrator_type)
    end

    def parameter_require_error
      render json: { message: 'Oops! An error has been occurred: Parameter(s) is required' },
             status: :unprocessable_entity
    end

    def raffle_is_closed_error
      render json: { message: 'Raffle is closed, try with other raffle' }, status: :forbidden
    end

    def fetch_tickets
      params.require(:raffle_id, :current_page, :items_per_page)
    end
  end
end
