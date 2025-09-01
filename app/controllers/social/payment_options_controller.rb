class Social::PaymentOptionsController < ApplicationController
  before_action :authorize_request, only: %i[ create update ]
  before_action :set_social_payment_option, only: %i[ update destroy ]
 
  def create    
    @social_payment_option = Social::PaymentOption.new(social_payment_option_params)

    @social_payment_option.social_influencer_id = @current_user.social_influencer.id

    dni_from_params = social_payment_option_params[:details][:dni]

    @social_payment_option.is_system_pay = "J-#{ENV["R4_CONECTA_COMMERCE_ID"]}" == dni_from_params

    if @current_user.social_influencer.nil?
      render json: { error: 'User is not an influencer' }, status: :forbidden
      return
    end

    if @social_payment_option.save
      render json: @social_payment_option, status: :created
    else
      render json: @social_payment_option.errors, status: :unprocessable_entity
    end
  end

  def update
    if @social_payment_option.nil?
      render json: { error: 'Payment option not found' }, status: :not_found
      return
    end

    if @social_payment_option.social_influencer_id != @current_user.social_influencer.id
      render json: { error: 'You are not authorized to update this payment option' }, status: :forbidden
      return
    end

    if @social_payment_option.update(edit_social_payment_option_params)
      render json: @social_payment_option, status: :ok
    else
      render json: @social_payment_option.errors, status: :unprocessable_entity
    end
  end

  def destroy
    if @social_payment_option.nil?
      render json: { error: 'Payment option not found' }, status: :not_found
      return
    end

    if @social_payment_option.social_influencer_id != @current_user.social_influencer.id
      render json: { error: 'You are not authorized to delete this payment option' }, status: :forbidden
      return
    end

    @social_payment_option.destroy
    render json: { message: 'Payment option deleted successfully', social_payment_option: @social_payment_option }, status: :ok
  end

  private

  def set_social_payment_option
    @social_payment_option = Social::PaymentOption.find_by(id: params[:id])
  end

  def edit_social_payment_option_params
    params.require(:social_payment_option).permit(
      :rate
    )
  end

  def social_payment_option_params
    params.require(:social_payment_option).permit(
      :name,
      :country,
      :social_influencer_id,
      details: [:bank, :name, :dni, :phone, :email, :direction, :key, :account, :accountType]
    )
  end
end
