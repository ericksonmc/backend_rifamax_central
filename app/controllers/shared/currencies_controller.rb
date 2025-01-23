class Shared::CurrenciesController < ApplicationController
  def index
    @currencies = Shared::Currency.all

    render json: @currencies, status: :ok
  end
end
