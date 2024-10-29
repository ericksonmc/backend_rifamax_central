class Shared::LobbyController < ApplicationController
  before_action :authorize_request

  def index
    @products = Shared::Product.allow_modules(@current_user.role, params[:devices])

    render json: @products, status: :ok
  end
  
  def create
    @product = Shared::Product.new(lobby_params)

    if @product.save
      render json: { message: "Product created", product: @product }, status: :created
    else
      render json: { error: @product.errors }, status: :unprocessable_entity
    end
  end

  private

  def lobby_params
    params.require(:product).permit(
      :to,
      :name,
      :image,
      :color,
      roles: [],
      devices: []
    )
  end
end
