# frozen_string_literal: true

class X100::OrdersController < ApplicationController
  before_action :authorize_request, except: %i[index bill]
  before_action :set_x100_order, only: %i[show update destroy]

  # GET /x100/orders
  def index
    @x100_orders = X100::Order.find_by(serial: fetch_order[:serial])

    if @x100_orders.nil?
      render json: { message: "Order with serial: #{fetch_order[:serial]} doesn't exist" }, status: :not_found
    else
      render json: @x100_orders, status: :ok
    end
  end

  # GET /x100/orders/bill?serial=ORD-12345678910
  def bill
    @order = X100::Order.find_by(serial: fetch_order[:serial])

    if @order.nil?
      render json: { message: 'Not found', status: 404 }, stauts: :not_found
    else
      render 'layouts/x100/orders/index', locals: { order: @order }
    end
  end

  # GET /x100/orders/1
  def show
    render json: @x100_order
  end

  # GET /x100/orders/by_structure?date=2024-01-01
  def by_structure
    date = Time.parse(params[:date]) || Time.now

    @x100_orders = X100::Order.order_by_structure(datetime: date)

    render json: @x100_orders, status: :ok
  end

  # POST /x100/orders
  def create
    @x100_order = X100::Order.new(x100_order_params)

    if @x100_order.save
      render json: @x100_order, status: :created, location: @x100_order
    else
      render json: @x100_order.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /x100/orders/1
  def update
    if @x100_order.update(x100_order_params)
      render json: @x100_order
    else
      render json: @x100_order.errors, status: :unprocessable_entity
    end
  end

  # DELETE /x100/orders/1
  def destroy
    @x100_order.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_x100_order
    @x100_order = X100::Order.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def x100_order_params
    params.require(:x100_order).permit(:products, :amount, :serial, :ordered_at, :shared_user_id, :x100_client_id)
  end

  def fetch_order
    params.permit(:serial)
  end
end
