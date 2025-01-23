class Rifamax::AgenciesController < ApplicationController
  before_action :authorize_request

  def index
    render json: serialize(@current_user.sellers), status: :ok
  end

  private

  def serialize(data)
    ActiveModelSerializers::SerializableResource.new(data, each_serializer: Rifamax::AgencySerializer).as_json
  end
end