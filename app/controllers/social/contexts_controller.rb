class Social::ContextsController < ApplicationController
  before_action :authorize_request
  before_action :allow_user_when_admin

  # POST /social/contexts
  def create
    @social_context = Social::Context.new(social_context_params)

    existing_context = Social::Context.find_by(key: @social_context.key)

    if existing_context
      render json: existing_context, status: :ok and return
    end

    if @social_context.save
      render json: @social_context, status: :created, location: @social_context
    else
      render json: @social_context.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /social/contexts
  def add
    @social_context = Social::Context.find_by(key: social_context_params[:key])

    if @social_context.update(social_context_params.except(:key))
      render json: @social_context
    else
      render json: @social_context.errors, status: :unprocessable_entity
    end
  end

  private

  def social_context_params
    params.require(:social_context).permit(
      :key, 
      context: [
        :client_id,
        :raffle_id,
        :last_agent_response,
        :last_user_message,
        :tickets_quantity,
        :payment_method_selected,
        :fractions,
        :current_user_step,
        payment_method_data: [
          :name,
          :email,
          :phone,
          :last_digits,
          :bank,
          :payment_date,
          :reference
        ]
      ]
    )
  end

  def allow_user_when_admin
    if !%w[Admin Desarrollador].include?(@current_user.role)
      render json: { message: "Unauthorized" }, status: :unauthorized
    end
  end
end
