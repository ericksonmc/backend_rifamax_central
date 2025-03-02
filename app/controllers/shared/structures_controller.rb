class Shared::StructuresController < ApplicationController
  before_action :authorize_request
  before_action :verify_is_admin, only: %i[index]

  def index
    @structures = Shared::Structure.where.not(access_to: ['DB']) .order(:id)
    render json: @structures, status: :ok
  end

  private

  def verify_is_admin
    if (@current_user.role != 'Admin')
      render json: { message: 'Unauthorized' }, status: :forbidden
    end
  end
end
