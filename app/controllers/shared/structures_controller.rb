class Shared::StructuresController < ApplicationController
  before_action :authorize_request

  def index
    @integrator_type = params[:integrator]
    @integrator_user_id = params[:player_id]
    @currency = params[:currency] | 'USD'
  end
end
