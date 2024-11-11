# frozen_string_literal: true

module Rifamax
  class TicketsController < ActionController::Base
    before_action :authorize_request, only: %i[sell_all]
    before_action :set_rifamax_ticket, only: %i[show update destroy]

    # GET /rifamax/tickets
    def index
      @tickets = Rifamax::Ticket.where(serial: params[:serial]).last
      @rifa = @tickets.rifamax_raffle

      if  @tickets.nil?
        render json: { message: 'Not found', status: 404 }, stauts: :not_found
      else
        render 'layouts/x100/orders/index', locals: { rifa: @rifa, tickets: @tickets }
      end
    end

    # GET /rifamax/tickets/get_tickets?raffle_id={id}
    def get_tickets
      @raffle = Rifamax::Raffle.find(params[:raffle_id])

      if @raffle
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
      rescue e
        render json: { message: e }, status: :unauthorized
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
        
      )
    end
  end
end
