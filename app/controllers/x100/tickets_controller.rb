# frozen_string_literal: true

module X100
  class TicketsController < ApplicationController
    before_action :authorize_request, except: [:refresh]
    before_action :fetch_tickets, only: [:index]
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
      @raffle = X100::Raffle.find(sell_x100_ticket_params[:x100_raffle_id])
      positions = sell_x100_ticket_params[:positions]
      success_sold = []

      if positions.blank? || @raffle.nil?
        parameter_require_error
      else

        ActiveRecord::Base.transaction do
          success_sold = validates_positions(positions)
          @integrator_client = X100::Client.find_by(
            integrator_id: sell_x100_ticket_params[:x100_client_id], integrator_type: sell_x100_ticket_params[:integrator]
          )

          render_ticket_not_sold(positions) if success_sold == 'Error'

          if success_sold.length == positions.length
            quantity = success_sold.length
            money = sell_x100_ticket_params[:money]

            if !sell_x100_ticket_params[:integrator].nil?
              raise ActiveRecord::Rollback, 'Failed to sell ticket' if sell_x100_ticket_params[:player_id].nil?

              @orders = X100::Order.new(
                products: success_sold,
                amount: @raffle.calculate_final_amount(quantity, money),
                serial: "ORD-#{SecureRandom.hex(8).upcase}",
                ordered_at: DateTime.now,
                money: money,
                shared_user_id: @current_user.id,
                x100_client_id: @integrator_client.id,
                x100_raffle_id: sell_x100_ticket_params[:x100_raffle_id],
                integrator_player_id: sell_x100_ticket_params[:player_id],
                integrator: sell_x100_ticket_params[:integrator],
                shared_exchange_id: Shared::Exchange.last.id
              )

              if @orders.integrator_job == false
                render json: { message: 'Integrator API failed at selling ticket, aborting transaction!' }, status: :unprocessable_entity
                raise ActiveRecord::Rollback, 'Integrator API failed at selling ticket, aborting transaction!'
                return
              end

              X100::Ticket.where(position: success_sold, x100_raffle_id: sell_x100_ticket_params[:x100_raffle_id]).update_all(
                price: X100::Raffle.find(@x100_ticket.x100_raffle_id).price_unit,
                money: ticket_params[:money],
                status: 'sold',
                x100_raffle_id: ticket_params[:x100_raffle_id],
                x100_client_id: if sell_x100_ticket_params[:integrator].nil?
                                  ticket_params[:x100_client_id]
                                else
                                  @integrator_client.id
                                end
              )
              @orders.save!
              broadcast_transaction

            else
              X100::Ticket.where(position: success_sold, x100_raffle_id: sell_x100_ticket_params[:x100_raffle_id]).update_all(
                price: X100::Raffle.find(@x100_ticket.x100_raffle_id).price_unit,
                money: ticket_params[:money],
                status: 'sold',
                x100_raffle_id: ticket_params[:x100_raffle_id],
                x100_client_id: if sell_x100_ticket_params[:integrator].nil?
                                  ticket_params[:x100_client_id]
                                else
                                  @integrator_client.id
                                end
              )
              @orders = X100::Order.new(
                products: success_sold,
                amount: @raffle.calculate_final_amount(quantity, money),
                serial: "ORD-#{SecureRandom.hex(8).upcase}",
                ordered_at: DateTime.now,
                money: sell_x100_ticket_params[:money],
                shared_user_id: @current_user.id,
                x100_client_id: sell_x100_ticket_params[:x100_client_id],
                x100_raffle_id: sell_x100_ticket_params[:x100_raffle_id],
                shared_exchange_id: Shared::Exchange.last.id
              )
              @orders.save!
              broadcast_transaction
            end
            render json: { message: 'Tickets sold', tickets: X100::Ticket.where(position: success_sold, x100_raffle_id: sell_x100_ticket_params[:x100_raffle_id]), order: @orders.serial },
                   status: :ok
          else
            render json: { message: "Oops! An error has occurred: #{success_sold.length} of #{positions.length} tickets sold" },
                   status: :unprocessable_entity
          end
        end
      end
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
          broadcast_transaction
          render json: { message: 'Tickets cleared!', is_cleared: true }, status: :ok
        rescue StandardError => e
          render json: { message: "Tickets can't be cleared!", is_cleared: false, error: e }, status: :unprocessable_entity
        end
      end
    end

    def apart_integrator
      @x100_ticket = X100::Ticket.find_by(position: apart_integrator_params[:position], x100_raffle_id: apart_integrator_params[:x100_raffle_id])

      if @x100_ticket.nil?
        render_not_found("Ticket with position: #{apart_integrator_params[:position]} can't be apart")
      elsif @x100_ticket.available?
        return raffle_is_closed_error if @x100_ticket.status == 'Cerrada'

        if (X100::Ticket.apart_ticket_integrator(@x100_ticket.id, apart_integrator_params[:integrator_id], apart_integrator_params[:integrator_type], apart_integrator_params[:money]) == true)
          broadcast_transaction
          render json: { message: 'Ticket aparted', ticket: @x100_ticket }, status: :ok
        else
          broadcast_transaction
          render json: { message: "Ticket with position: #{apart_integrator_params[:position]} can't be apart", error: X100::Ticket.apart_ticket_integrator(@x100_ticket.id, apart_integrator_params[:integrator_id], apart_integrator_params[:integrator_type], apart_integrator_params[:money]) },
                 status: :unprocessable_entity
        end
      else
        render json: { message: "Ticket with position: #{apart_integrator_params[:position]} can't be apart" },
               status: :unprocessable_entity
      end
    end

    def refresh
      broadcast_transaction

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
            broadcast_transaction
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
      broadcast_transaction
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
        broadcast_transaction
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

    def broadcast_transaction
      @tickets = X100::Ticket.all_sold_tickets
      @raffles = X100::Raffle.current_progress_of_actives

      ActionCable.server.broadcast('x100_raffles', @raffles)
      ActionCable.server.broadcast('x100_tickets', @tickets)
    end

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
      render json: { message: "Resource can't be found" }, status: :not_found
    end

    def sell_series_ticket_params
      params.require(:series_ticket).permit(:raffle_id, :client_id, :integrator, :money, :quantity)
    end

    def sell_x100_ticket_params
      params.require(:x100_ticket).permit(:x100_raffle_id, :x100_client_id, :price, :money, :integrator, :player_id,
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
