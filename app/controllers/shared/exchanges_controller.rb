class Shared::ExchangesController < ApplicationController
  before_action :authorize_request, except: %i[index bcv]
  before_action :set_shared_exchange, only: %i[show update destroy]
  before_action :allow_user_when_admin, only: %i[create update destroy]

  # GET /shared/exchanges
  def index
    date_param = params[:date]
    date =
      begin
        date_param.present? ? Date.parse(date_param) : Date.current.to_s
      rescue ArgumentError
        return render json: { error: 'Invalid date format. Use YYYY-MM-DD.' }, status: :unprocessable_entity
      end
    
    @shared_exchanges =  Shared::Exchange.where(created_at: Date.parse(date).all_day).order(:created_at).last

    @result = {
      value_bs: Social::R4ConectaService.new.consultar_tasa_bcv(fechavalor: date)["tipocambio"].round(2),
      value_cop: @shared_exchanges.value_cop,
      mainstream_money: @shared_exchanges.mainstream_money,
      automatic: @shared_exchanges.automatic,
      created_at: @shared_exchanges.created_at.strftime('%Y-%m-%d %H:%M:%S'),
      updated_at: @shared_exchanges.updated_at.strftime('%Y-%m-%d %H:%M:%S')
    }

    render json: @shared_exchanges, status: :ok
  end

  # GET /shared/exchanges/1
  def show
    render json: @shared_exchange
  end

  # POST /shared/exchanges
  def create
    @shared_exchange = Shared::Exchange.new(shared_exchange_params)

    if @shared_exchange.save
      render json: @shared_exchange, status: :created, location: @shared_exchange
    else
      render json: @shared_exchange.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /shared/exchanges/1
  def update
    if @shared_exchange.update(shared_exchange_params)
      render json: @shared_exchange
    else
      render json: @shared_exchange.errors, status: :unprocessable_entity
    end
  end

  # DELETE /shared/exchanges/1
  def destroy
    if @shared_exchange.destroy
      render json: { message: "Exchange deleted" }, status: :ok
    else
      render json: @shared_exchange.errors, status: :unprocessable_entity
    end
  end

  private

  def allow_user_when_admin
    render json: { message: "Unauthorized" }, status: :unauthorized
  end
  
  def set_shared_exchange
    @shared_exchange = Shared::Exchange.find(params[:id])
  end

  def shared_exchange_params
    params.require(:shared_exchange).permit(:value_bs, :value_cop, :mainstream_money, :automatic)
  end
end
