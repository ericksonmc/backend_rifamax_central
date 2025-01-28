class Shared::LotteriesController < ApplicationController
  def index
    @lotteries = Shared::Lottery.all.order(created_at: :desc)

    render json: @lotteries, status: :ok
  end
end
