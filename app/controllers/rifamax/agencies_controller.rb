class Rifamax::AgenciesController < ApplicationController
  before_action :authorize_request

  def index
    render json: serialize(Rifamax::Agency.all), status: :ok
  end

  private

  def serialize(data)
    ActiveModelSerializers::SerializableResource.new(data, each_serializer: Rifamax::AgencySerializer).as_json
end
