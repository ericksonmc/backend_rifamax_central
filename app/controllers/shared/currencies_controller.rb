class Shared::CurrenciesController < ApplicationController
  def index
    @currencies = Shared::Currency.all.order(:id)

    render json: @currencies, status: :ok
  end
end
