class Rifamax::AgenciesController < ApplicationController
  before_action :authorize_request

  def index
    render json: SerializableResource.new(@current_user.sellers, each_serializer: Rifamax::AgencySerializer).as_json, status: :ok
  end
end
