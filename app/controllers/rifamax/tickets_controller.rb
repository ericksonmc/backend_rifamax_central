# frozen_string_literal: true

module Rifamax
  class TicketsController < ApplicationController
    before_action :authorize_request, only: %i[sell_all sell_some sell_all_tickets]
    before_action :set_rifamax_ticket, only: %i[show update destroy]

    # GET /rifamax/tickets
    def index
      @tickets = Rifamax::Ticket.where(serial: params[:serial]).last
      @rifa = @tickets.rifamax_raffle

      if  @tickets.nil?
        render json: { message: 'Not found', status: 404 }, status: :not_found
      else
        render 'layouts/x100/orders/index', locals: { rifa: @rifa, tickets: @tickets }
      end
    end

    # GET /rifamax/tickets/get_tickets?raffle_id={id}
    def get_tickets
      @raffle = Rifamax::Raffle.find(params[:raffle_id])

      if @raffle
        if @raffle.tickets.where(is_sold: false).count == 0
          @raffle.update(
            sell_status: 2
          )
        end
        render json: @raffle.tickets, status: :ok
      else
        render json: "Raffle doesn't exist", status: :not_found
      end
    end

    # POST /rifamax/tickets/sell_all
    def sell_all
      begin
        @raffle = Rifamax::Raffle.find(params[:raffle_id])
        @raffle.user_who_requested = @current_user.id
        render json: @raffle.sell_all_tickets, status: :ok
      rescue StandardError => e
        render json: { message: e }, status: :unauthorized
      end  
    end

    # GET /rifamax/tickets/1
    def show
      render json: @rifamax_ticket
    end

    # POST /rifamax/tickets
    def create
      @rifamax_ticket = Rifamax::Ticket.new(rifamax_ticket_params)

      if @rifamax_ticket.save
        render json: @rifamax_ticket, status: :created, location: @rifamax_ticket
      else
        render json: @rifamax_ticket.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /rifamax/tickets/1
    def update
      if @rifamax_ticket.update(rifamax_ticket_params)
        render json: @rifamax_ticket
      else
        render json: @rifamax_ticket.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /rifamax/tickets/sell_some
    def sell_some
      begin
        @tickets_ids = params[:tickets_ids] || []
        @raffle = Rifamax::Raffle.find(params[:raffle_id])
        @raffle.user_who_requested = @current_user.id
        render json: @raffle.sell_some_tickets(@tickets_ids), status: :ok
      rescue StandardError => e
        render json: { message: e }, status: :unprocessable_entity
      end  
    end

    def sell_all_tickets
      @raffle = Rifamax::Raffle.find(params[:raffle_id])
      @raffle.user_who_requested = @current_user.id

      @raffle.sell_all_tickets_withoud_paid

      @tickets_strings = Rifamax::TicketsString.new(@raffle.tickets).generate_strings

      render json: {
        message: "All tickets have been sold!",
        tickets: Rifamax::TicketSerializer.new(@raffle.tickets).object,
        tickets_strings: @tickets_strings
      }, status: :ok

    rescue StandardError => e
      render json: { message: e }, status: :unprocessable_entity
    end

    # DELETE /rifamax/tickets/1
    def destroy
      @rifamax_ticket.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_rifamax_ticket
      @rifamax_ticket = Rifamax::Ticket.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def rifamax_ticket_params
      params.require(:rifamax_ticket).permit(
        :is_sold
      )
    end
  end
end
