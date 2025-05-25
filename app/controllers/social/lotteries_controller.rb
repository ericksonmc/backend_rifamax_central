class Social::LotteriesController < ApplicationController
  before_action :authorize_request, except: %i[available]
  before_action :authorize_admin, except: %i[available]
  before_action :set_social_lottery, only: %i[ toggle_status show update destroy ]

  # GET /social/lotteries
  def index
    @social_lotteries = Social::Lottery.all

    render json: @social_lotteries, status: :ok
  end

  # GET /social/lotteries/available
  def available
    @social_lotteries = Social::Lottery.available_lotteries

    render json: @social_lotteries, status: :ok
  end

  # GET /social/lotteries/1
  def show
    render json: @social_lottery
  end

  # POST /social/lotteries
  def create
    @social_lottery = Social::Lottery.new(social_lottery_params)

    if @social_lottery.save
      render json: @social_lottery, status: :created, location: @social_lottery
    else
      render json: @social_lottery.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /social/lotteries/toggle_status/1
  def toggle_status
    @social_lottery.toggle_status!
    render json: @social_lottery, status: :ok
  end

  # PATCH/PUT /social/lotteries/1
  def update
    if @social_lottery.update(social_lottery_params)
      render json: @social_lottery
    else
      render json: @social_lottery.errors, status: :unprocessable_entity
    end
  end

  # DELETE /social/lotteries/1
  def destroy
    @social_lottery.destroy
    render json: { message: 'Lottery deleted successfully' }, status: :ok
  end

  private

  def authorize_admin
    unless @current_user.role == 'Admin'
      render json: { error: 'You are not authorized to perform this action.' }, status: :forbidden
    end 
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_social_lottery
    @social_lottery = Social::Lottery.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def social_lottery_params
    params.require(:social_lottery).permit(:name, :profit_fee, :key_name)
  end
end
