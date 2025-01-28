class Shared::LotteriesController < ApplicationController
  def index
    @lotteries = Shared::Lottery.all.order(id: :asc)

    render json: @lotteries, status: :ok
  end
end
