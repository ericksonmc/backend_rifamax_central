class Rifamax::AgenciesController < ApplicationController
  before_action :authorize_request

  def index
    render json: @current_user.sellers, status: :ok
  end
end
