# frozen_string_literal: true

class AuthenticationController < ApplicationController
  before_action :authorize_request, except: %i[login social_login refresh integrator_login]
  before_action :soft_authorize_request, only: %i[refresh social_refresh]
  
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
    @email = params[:email]
    @password = params[:password]
    @token = params[:token]
    @structure = Shared::Structure.find_by(token: @token)

    if @token.nil? || @structure.nil?
      @user = Shared::User.where(structure: @structure.id).find_by_email(params[:email])

      if @user&.authenticate(params[:password])
        time = 7.days.from_now
        token = JsonWebToken.encode(
          {
            user_id: @user.id
          }, 
          time
        )
        render json: { token:, exp: time.strftime('%m-%d-%Y %H:%M'),
                       user: Shared::UserSerializer.new(@user) }, status: :ok
      else
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end

    else
      render json: { message: 'Integrator token not found' }, status: :not_found
    end
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
