class Social::InfluencersController < ApplicationController
  include Pagy::Backend

  before_action :authorize_request, only: %i[all search]
  before_action :validates_roles, only: %i[all search]

  # GET /influencers/:content_code
  def index
    @influencer = Social::Influencer.find_by(content_code: params[:content_code])
    
    if @influencer
      render json: @influencer.shared_user, status: :ok, status: :ok
    else
      render json: { message: 'Influencer not found' }, status: :not_found
    end
  end

  # GET /influencers/search
  def search
    @lottery = Social::Lottery.find_by(shared_user_id: Shared::User.find(481).id)
    
    @influencers = Shared::User.where('phone ilike ? OR email ilike ? OR name ilike ? OR dni ilike ?', "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%").where(role: 'Influencer')

    @result = if @current_user.Loteria?
                @influencers.where(lotteries: [@lottery.id])
              else
                @influencers
              end
  
    count = params[:count] || 4
    page = params[:page] || 1

    @pagy, @records = pagy(@result, items: count, page: page)
    render json: {
      influencers: ActiveModel::Serializer::CollectionSerializer.new(@records, each_serializer: Shared::UserSerializer),
      metadata: {
        page: @pagy.page,
        count: @pagy.count,
        items: @pagy.items,
        pages: @pagy.pages
      }
    }, status: :ok
  end

  # GET /influencers/all
  def all
    @lottery = Social::Lottery.find_by(shared_user_id: @current_user.id)
    @influencers = @lottery.nil? ? Social::Influencer.all : Social::Influencer.where(lotteries: [@lottery.id])
    count = params[:count] || 6
    page = params[:page] || 1

    @pagy, @records = pagy(@influencers, items: count, page: page)
    render json: { 
      influencers: ActiveModel::Serializer::CollectionSerializer.new(@records, each_serializer: Social::InfluencerSerializer), 
      metadata: {
        page: @pagy.page,
        count: @pagy.count,
        items: @pagy.items,
        pages: @pagy.pages
      }
    }, status: :ok

    rescue Pagy::OverflowError
      render json: { error: 'Pagy Out of range' }, status: 400
  end

  private

  def validates_roles
    roles = ['Admin', 'Loteria']

    return if roles.include?(@current_user.role)

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
