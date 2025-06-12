class Social::LotteriesController < ApplicationController
  before_action :authorize_request, except: %i[available]
  before_action :authorize_admin, except: %i[available profile]
  before_action :authorize_lottery, only: %i[profile]
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

  # GET /social/lotteries/profile
  def profile
    @lottery = Social::Lottery.find_by(shared_user_id: @current_user.id)

    render json: @lottery, status: :ok, location: @lottery
  end

  # POST /social/lotteries
  def create
    user_params = social_lottery_params
                    .slice(:email, :password)
                    .merge(id: Shared::User.last.id + 1, role: 'loteria', is_first_entry: false, welcoming: false, name: social_lottery_params[:name])

    lottery_params = social_lottery_params.slice(:name, :profit_fee, :key_name)                   
  
    @shared_user = Shared::User.new(user_params)
    @social_lottery = Social::Lottery.new(lottery_params)
  
    ActiveRecord::Base.transaction do
      @shared_user.save!
      @social_lottery.shared_user_id = @shared_user.id
      @social_lottery.save!
    end
  
    render json: @social_lottery, status: :created, location: @social_lottery
  
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
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
    params.require(:social_lottery).permit(:name, :profit_fee, :key_name, :email, :password)
  end
end
