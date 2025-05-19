# frozen_string_literal: true

module Rifamax
  class RafflesController < ApplicationController
    include Pagy::Backend

    # before_action :set_rifamax_raffle, only: %i[show update destroy]
    before_action :authorize_request, except: %i[report]

    # GET /rifamax/raffles
    def index
      page = params[:page] || 1
      items = params[:items] || 7

      @pagy, @records = pagy(
        Rifamax::Raffle.active_today(@current_user.id).unscoped.order("id DESC"), 
        page: page, 
        items: items
      )

      render json: { 
        raffles: serialize(@records), 
        metadata: {
          count: @pagy.count,
          page: @pagy.page,
          items: @pagy.items,
          pages: @pagy.pages
        }
      }
    end

    # GET /rifamax/raffles/newest
    def newest
      page = params[:page] || 1
      items = params[:items] || 7

      @pagy, @records = pagy(
        Rifamax::Raffle.filter_by_status(@current_user.id, 'newest').unscoped.order("id DESC"), 
        page: page, 
        items: items
      )

      render json: { 
        raffles: serialize(@records), 
        metadata: {
          count: @pagy.count,
          page: @pagy.page,
          items: @pagy.items,
          pages: @pagy.pages
        }
      }
    end

    # GET /rifamax/raffles/initialized
    def initialized
      page = params[:page] || 1
      items = params[:items] || 7

      @pagy, @records = pagy(
        Rifamax::Raffle.filter_by_status(@current_user.id, 'initialized').where('expired_date >= ?', Date.today).unscoped.order("id DESC"), 
        page: page, 
        items: items
      )

      render json: { 
        raffles: serialize(@records), 
        metadata: {
          count: @pagy.count,
          page: @pagy.page,
          items: @pagy.items,
          pages: @pagy.pages
        }
      }
    end

    # GET /rifamax/raffles/to_close
    def to_close
      page = params[:page] || 1
      items = params[:items] || 7

      @pagy, @records = pagy(
        Rifamax::Raffle.filter_by_status(@current_user.id, 'to_close').where('expired_date < ?', Date.today).unscoped.order("id DESC"), 
        page: page, 
        items: items
      )

      render json: { 
        raffles: serialize(@records), 
        metadata: {
          count: @pagy.count,
          page: @pagy.page,
          items: @pagy.items,
          pages: @pagy.pages
        }
      }
    end

    # POST /rifamax/raffles/send_app
    def send_app
      @rifamax_raffle = Rifamax::Raffle.find(params[:raffle_id])
      if @rifamax_raffle.sent!
        @rifamax_raffle.update(expired_date: Date.today + 3.days)
        render json: @rifamax_raffle
      else
        render json: @rifamax_raffle.errors, status: :unprocessable_entity
      end
    end

    # GET /rifamax/raffles/is_block
    def is_blocked
      render json: @current_user.zodiacal_is_blocked, status: :ok
    end

    # POST /rifamax/raffles/print
    def print
      @rifamax_raffle = Rifamax::Raffle.find(params[:raffle_id])
      if @rifamax_raffle.sold!
        @rifamax_raffle.update(expired_date: Date.today + 3.days)
        render json: @rifamax_raffle
      else
        render json: @rifamax_raffle.errors, status: :unprocessable_entity
      end
    end

    # POST /rifamax/raffles/print
    def sell
      @rifamax_raffle = Rifamax::Raffle.find(params[:raffle_id])
      if @rifamax_raffle.sold!
        render json: @rifamax_raffle
      else
        render json: @rifamax_raffle.errors, status: :unprocessable_entity
      end
    end

    # GET /rifamax/raffles/report
    def report
      render 'layouts/x100/rifamax/raffles/index'
    end

    # POST /rifamax/raffles/pay
    def pay
      @rifamax_raffle = Rifamax::Raffle.find(rifamax_raffle_pay_params[:id])
      if @rifamax_raffle.admin_status == 'pending'
        if @rifamax_raffle.update(admin_status: 1, payment_info: rifamax_raffle_pay_params[:payment_info], details: rifamax_raffle_pay_params[:details])
          render json: @rifamax_raffle
        else
          render json: { message: "Can't pay this raffle" }, status: :unprocessable_entity
        end
      else
        render json: { message: "Can't move status" }, status: :unprocessable_entity
      end
    end

    # POST /rifamax/raffles/triple_pay
    def triple_pay
      @tokenspj = request.headers['Tokenspj']
      @cda_jwt = request.headers['cdajwt']
      @subdomain = request.headers['subdomain']
      @cda_sell_type = rifamax_raffle_triple_pay_params[:cda_sell_type]
      @payload = rifamax_raffle_triple_pay_params[:payload]
      @payment_info = rifamax_raffle_triple_pay_params[:payment_info]

      @rifamax_raffle = Rifamax::Raffle.find(rifamax_raffle_triple_pay_params[:id])
      
      @rifamax_raffle.cda_sell_type = @cda_sell_type
      @rifamax_raffle.subdomain = @subdomain
      @rifamax_raffle.tokenspj = @tokenspj
      @rifamax_raffle.cda_jwt = @cda_jwt
      @rifamax_raffle.payload = @payload.to_json.to_s
      @rifamax_raffle.payment_pre_info = @payment_info
      @rifamax_raffle.is_integration = true

      result = @rifamax_raffle.handle_cda_payment

      render json: result, status: :ok
    rescue StandardError => e
        render json: { exception: e }, status: :unprocessable_entity
    end

    # POST /rifamax/raffles/unpay
    def unpay
      @rifamax_raffle = Rifamax::Raffle.find(params[:raffle_id])
      if @rifamax_raffle.admin_status == 'pending'
        @rifamax_raffle.update(admin_status: 2)
        render json: @rifamax_raffle
      else
        render json: { message: "Can't move status" }, status: :unprocessable_entity
      end
    end

    # POST /rifamax/raffles/refund
    def refund
      @rifamax_raffle = Rifamax::Raffle.find(params[:raffle_id])
      if @rifamax_raffle.admin_status == 'pending'
        @rifamax_raffle.update(admin_status: 3)
        render json: @rifamax_raffle
      else
        render json: { message: "Can't move status" }, status: :unprocessable_entity
      end
    end

    # POST /rifamax/raffles/repeat
    def repeat
      @rifamax_raffle = Rifamax::Raffle.find(params[:raffle_id]).dup
     
      @rifamax_raffle.init_date = params[:init_date] || Date.tomorrow
      @rifamax_raffle.lotery = params[:lotery] || 'Zulia 7A'
      @rifamax_raffle.numbers = params[:numbers] || 777
      @rifamax_raffle.expired_date = nil
      @rifamax_raffle.admin_status = 0
      @rifamax_raffle.sell_status = 0

      if @rifamax_raffle.save
        render json: @rifamax_raffle
      else
        render json: { message: "Can't save, try later", error: @rifamax_raffle.errors }, status: :unprocessable_entity
      end
    end

    # GET /rifamax/raffles/close_day
    def close_day
      @raffles = Rifamax::Raffle.filter_by_status(@current_user.id, 'initialized').where('expired_date >= ?', Date.today)

      render json: {
        message: 'Fetched',
        raffles: Rifamax::RaffleSerializer.new(@raffles).object
      }
    end

    # GET /rifamax/raffles/close_day_info
    def close_day_info
      @raffles = Rifamax::Raffle.stats(Rifamax::Raffle.active.where(user_id: @current_user.id))

      render json: @raffles, status: :ok
    end

    # GET /rifamax/raffles/1
    def show
      render json: @rifamax_raffle, status: :ok
    end

    # POST /rifamax/raffles
    def create
      @rifamax_raffle = Rifamax::Raffle.new(rifamax_raffle_params)
      @rifamax_raffle.user_id = @current_user.id
      @rifamax_raffle.need_buy = true

      if @rifamax_raffle.save
        render json: @rifamax_raffle, status: :created, location: @rifamax_raffle
      else
        render json: @rifamax_raffle.errors, status: :unprocessable_entity
      end
    end

    # POST /rifamax/raffles/seller_create
    def seller_create
      @rifamax_raffle = Rifamax::Raffle.new(rifamax_raffle_params)
      @rifamax_raffle.sell_status = 1
      @rifamax_raffle.admin_status = 0
      @rifamax_raffle.skip_status = true
      # @rifamax_raffle.lotery = 'Triple Rifamax Zodiacal'
      @rifamax_raffle.buy_currency = rifamax_raffle_params[:currency]
      @rifamax_raffle.user_id = @current_user.id
      @rifamax_raffle.seller_id = @current_user.id
      @rifamax_raffle.expired_date = 1.days.from_now
      @rifamax_raffle.need_buy = true
      @rifamax_raffle.is_integration = true

      if @rifamax_raffle.save
        render json: @rifamax_raffle, status: :created, location: @rifamax_raffle
      else
        render json: @rifamax_raffle.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /rifamax/raffles/1
    def update
      if @rifamax_raffle.update(rifamax_raffle_params)
        render json: @rifamax_raffle
      else
        render json: @rifamax_raffle.errors, status: :unprocessable_entity
      end
    end

    # DELETE /rifamax/raffles/1
    def destroy
      if @rifamax_raffle.destroy
        render json: { message: 'Raffle has been deleted' }
      else
        render json: { message: 'Raffle has not been deleted' }
      end
    end

    private

    def serialize(raffles)
      ActiveModelSerializers::SerializableResource.new(raffles, each_serializer: Rifamax::RaffleSerializer)
    end

    # def set_rifamax_raffle
    #   @rifamax_raffle = Rifamax::Raffle.find(params[:id])
    # end

    def rifamax_raffle_pay_params
      params.require(:rifamax_raffle).permit(
        :id,
        :details,
        payment_info: [:price, :currency]
      )
    end

    def rifamax_raffle_triple_pay_params
      params.require(:rifamax_raffle).permit(
        :id,
        :cda_sell_type,
        payment_info: [:price, :currency],
        payload: [
          :fec, :ts, :correo, :compress, :cupon, :usa_cupon, :app, :jp, 
          :ani, :tip, :uti, :cod, :ven, :ani_tipo, :producto_id, :codagen,
          :beneficiencia, :cda, :loterias, :cajero_id, :cedula, :nt,
          :telefono, :banco_id, :ticket, :moneda_id,
          jug: [:i, :n, :s, :c, :m],
        ]
      )
    end

    def rifamax_raffle_params
      params.require(:rifamax_raffle).permit(
        :title,
        :init_date,
        :price,
        :buy_amount,
        :numbers,
        :currency,
        :lotery,
        :seller_id,
        :user_id,
        prizes: [:award, :plate, :year, :is_money, :wildcard]
      )
    end
  end
end
