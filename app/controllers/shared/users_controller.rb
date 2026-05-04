# frozen_string_literal: true

module Shared
  class UsersController < ApplicationController
    before_action :set_shared_user, only: %i[show update destroy]
    before_action :authorize_request, except: %i[sign_up]
    before_action :allow_if_user_is_admin, only: %i[index show update destroy]
    before_action :allow_loteries_and_admins, only: %i[create toggle_active]
    
    # GET /shared/users
    def index
      @shared_users = Shared::User.all

      render json: @shared_users
    end

    # GET /shared/users/profile
    def profile
      render json: @current_user
    end

    # POST /shared/users/avatar
    def avatar
      if @current_user.update(shared_avatar_params)
        render json: @current_user, status: :ok
      else
        render json: { error: @current_user.errors, message: 'Avatar not uploaded' }, status: :unprocessable_entity
      end
    end

    # GET /shared/users/rafflers_list
    def rafflers_list
      rafflers = @current_user.rafflers_list

      render json: { data: rafflers }, status: :ok
    end

    # GET /shared/users/rafflers
    def rafflers
      rafflers = @current_user.rafflers
      excepted_attr = [:module_assigned, :is_integration, :password_digest, :rifero_ids, :created_at, :updated_at, :slug]
      @pagy, @records = pagy(rafflers, items: params[:items] || 10, page: params[:page])

      render json: {
        rafflers: @records.as_json(except: excepted_attr),
        metadata: {
          page: @pagy.page,
          count: @pagy.count,
          items: @pagy.items,
          pages: @pagy.pages
        }
      }

    rescue Pagy::OverflowError
      render json: { error: 'Pagy Out of range' }, status: 400
    rescue
      render json: { error: "Insufficient permissions to complete request" }, status: 403
    end

    # GET /shared/users/1
    def show
      render json: @shared_user, status: :ok
    end

    # PUT /shared/users/new_terms
    def new_terms
      if @current_user.update_attribute('welcoming', false)
        render json: @current_user, status: :ok
      else 
        render json: { error: 'Something was happened!' }, status: :unprocessable_entity
      end
    end

    # POST /shared/users
    def create
      @shared_user = Shared::User.new(shared_user_params)
      @shared_user.is_active = true
    
      if @current_user.Loteria?
        @lottery = Social::Lottery.find_by(shared_user_id: @current_user.id)
        unless @lottery
          render json: { message: "Lottery not found" }, status: :not_found and return
        end
        @shared_user.lotteries = [@lottery.id]
      end
    
      if @shared_user.save
        render json: @shared_user, status: :created, location: @shared_user
      else
        render json: { errors: @shared_user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # POST /shared/users/sign_up
    def sign_up
      ActiveRecord::Base.transaction do
        @shared_user = Shared::User.new(shared_user_params)
        @shared_user.id = Shared::User.last.id + 1
        @shared_user.is_active = true
        @shared_user.role = 'Rifero'

        unless Shared::Structure.find_by(token: params[:integrator_token])
          render json: { message: 'Integrator not found' }, status: :not_found
          return
        end

        @integrator = Shared::Structure.find_by(token: params[:integrator_token]).shared_user

        if @shared_user.save
          if @integrator.add_seller(@shared_user.id)
            render json: @shared_user, status: :created, location: @shared_user
          else
            ActiveRecord::Rollback
            render json: { message: 'Oops! somenthing has been happened' }, status: :forbidden
          end
        else
          ActiveRecord::Rollback
          render json: { message: 'Oops! somenthing has been happened' }, status: :unprocessable_entity
        end
      end
    end

    # PATCH/PUT /shared/users/1
    def update
      if @shared_user.update(shared_user_params)
        render json: @shared_user
      else
        render json: @shared_user.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /shared/users/welcome
    def welcome
      if @current_user.is_first_entry == true
        @current_user.social_influencer.update(content_code: welcome_params[:content_code]) if @current_user.role == 'Influencer'

        if @current_user.update(welcome_params.except(:content_code).merge(is_first_entry: false))
          render json: @current_user, status: :accepted
        else
          render json: @current_user.errors, status: :unprocessable_entity
        end
      else
        render json: { error: 'User already welcomed' }, status: 400
      end
    end

    def toggle_active
      user = Shared::User.find(params[:id])

      if user.update(is_active: !user.is_active)
        render json: { message: 'User updated', user: user }, status: :ok
      else
        render json: user.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /shared/users/update_influencer
    def update_influencer
      if @current_user.authenticate(influencer_params[:old_password])
        @current_user.social_influencer.update(content_code: welcome_params[:content_code]) if @current_user.role == 'Influencer'

        if @current_user.update(influencer_params.except(:old_password, :content_code))
          render json: @current_user, status: :accepted
        else
          render json: @current_user.errors, status: :unprocessable_entity
        end
      else
        render json: { error: 'Invalid password' }, status: 400
      end
    end

    # PATCH/PUT /shared/users/change_password
    def change_password
      if @current_user.authenticate(password_params[:old_password])
        if @current_user.update(password_params.except(:old_password))
          render json: { message: 'Password updated' }, status: :accepted
        else
          render json: @current_user.errors, status: :unprocessable_entity
        end
      else
        render json: { error: 'Invalid password' }, status: 400
      end
    end

    # DELETE /shared/users/1
    def destroy
      if @shared_user.destroy
        render json: { message: 'User deleted', user: @shared_user }, status: :ok, location: @shared_user
      else
        render json: @shared_user.errors, status: :unprocessable_entity
      end
    end

    private

    def allow_if_user_is_admin
      render json: { error: 'Not Authorized' }, status: 401 unless @current_user.role == 'Admin'
    end

    def allow_loteries_and_admins
      roles = ['Admin', 'Loteria']
      render json: { error: 'Not Authorized' }, status: 401 unless roles.include?(@current_user.role)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_shared_user
      @shared_user = Shared::User.find(params[:id])
    end

    def password_params
      params.require(:shared_user).permit(:old_password, :password, :password_confirmation)
    end

    def influencer_params
      params.require(:shared_user).permit(:content_code, :old_password, :password, :password_confirmation)
    end

    def welcome_params
      params.require(:shared_user).permit(:password, :password_confirmation, :content_code)
    end

    def shared_user_params
      params.require(:shared_user).permit(
        :avatar, 
        :name, 
        :role, 
        :dni, 
        :email, 
        :phone, 
        :integrator_token,
        :password, 
        :password_confirmation, 
        :slug,
        :is_active, 
        :module_assigned
      )
    end

    def shared_avatar_params
      params.require(:shared_user).permit(:avatar)
    end
  end
end
