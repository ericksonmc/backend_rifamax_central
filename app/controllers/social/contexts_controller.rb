class Social::ContextsController < ApplicationController
  before_action :authorize_request
  before_action :allow_user_when_admin
  before_action :set_social_context, only: %i[ show update destroy ]

  # GET /social/contexts
  def index
    @social_contexts = Social::Context.all

    render json: @social_contexts
  end

  # GET /social/contexts/{key}
  def show
    render json: @social_context
  end

  # POST /social/contexts
  def create
    @social_context = Social::Context.new(social_context_params)

    if @social_context.save
      render json: @social_context, status: :created, location: @social_context
    else
      render json: @social_context.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /social/contexts/{key}
  def update
    if @social_context.update(social_context_params)
      render json: @social_context
    else
      render json: @social_context.errors, status: :unprocessable_entity
    end
  end

  # DELETE /social/contexts/{key}
  def destroy
    if @social_context.destroy
      render json: { message: "Context deleted", context: @social_context }, status: :ok
    else
      render json: @social_context.errors, status: :unprocessable_entity
    end
  end

  private
  
  def set_social_context
    @social_context = Social::Context.by_key(params[:id])
  end

  def social_context_params
    params.require(:social_context).permit(:key, :context)
  end

  def allow_user_when_admin
    if !%w[Admin Desarrollador].include?(@current_user.role)
      render json: { message: "Unauthorized" }, status: :unauthorized
    end
  end
end
