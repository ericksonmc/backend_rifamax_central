# frozen_string_literal: true

class AuthenticationController < ApplicationController
  before_action :authorize_request, except: %i[login social_login refresh integrator_login]
  before_action :soft_authorize_request, only: %i[refresh social_refresh]
  before_action :validate_integration_token, only: %i[integrator_login]
  
  # POST /auth/login
  def login
    @user = Shared::User.find_by_email(params[:email])
    if @user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: @user.id)
      time = Time.now + 7.days.to_i
      render json: { token:, exp: time.strftime('%m-%d-%Y %H:%M'),
                     user: Shared::UserSerializer.new(@user) }, status: :ok
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  # POST /admin/login
  def social_login
    @user = Shared::User.find_by_email(params[:email])
    allowed_roles = %w[Admin Influencer]

    if @user&.authenticate(params[:password]) && allowed_roles.include?(@user.role)
      token = JsonWebToken.encode(user_id: @user.id, exp: 15.days.from_now)
      time = Time.now + 15.days.to_i
      render json: { token:, exp: time.strftime('%m-%d-%Y %H:%M'),
                     user: Shared::UserSerializer.new(@user) }, status: :ok
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  # POST /auth/connect/login
  def integrator_login
    @username = params[:username]
    @password = params[:password]
    @structure_id = params[:structure_id]
    @structure_type = params[:structure_type]

    result = Shared::User.login_integration(@username, @password, @structure_id, @structure_type)

    render json: result, status: :ok
  end

  # POST /social/auth/refresh
  def social_refresh
    roles_authorized = %w[Admin Influencer]

    token = JsonWebToken.encode(user_id: @soft_user.id, exp: 15.days.from_now)
    time = Time.now + 15.days.to_i

    if roles_authorized.include?(@soft_user.role)
      render json: { token:, exp: time.strftime('%m-%d-%Y %H:%M'),
                      user: Shared::UserSerializer.new(@soft_user) }, status: :ok
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  # POST /auth/profile
  def profile
    render json: @current_user, status: :ok
  end

  # POST /auth/verify_trz_access
  def verify_trz_access
    roles_allowed = %w[Admin].freeze

    if roles_allowed.include?(@current_user.role)
      render json: @current_user, status: :ok
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def refresh
    token = JsonWebToken.encode(user_id: @soft_user.id, exp: 15.days.from_now)
    time = Time.now + 15.days.to_i
    render json: { token:, exp: time.strftime('%m-%d-%Y %H:%M'),
                    user: Shared::UserSerializer.new(@soft_user), header: @token }, status: :ok
  end

  private

  def login_params
    params.permit(:email, :password)
  end
end
