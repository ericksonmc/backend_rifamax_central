class Social::RafflesController < ApplicationController
  include Pagy::Backend

  before_action :set_social_raffle, only: %i[ show update destroy ]
  before_action :authorize_request, only: %i[ index show create update destroy ]

  # GET /social/raffles
  def index
    @social_raffles = Social::Raffle.active

    if @current_user.role == 'Admin'
      render json: @social_raffles, status: :ok
    else
      render json: { error: 'No authorized to perform this action' }, status: :forbidden
    end
  end

  # GET /social/raffles/actives?content_code={content_code}&count={count}&page={page}
  def actives
    influencer = Social::Influencer.find_by(content_code: params[:content_code])
    count = params[:count] || 3
    page = params[:page] || 1

    if influencer
      @raffles = influencer.actives_raffles
      @pagy, @records = pagy(@raffles, items: count, page: page)
      render json: { 
        social_raffles: ActiveModel::Serializer::CollectionSerializer.new(@records, each_serializer: Social::RaffleSerializer),
        metadata: {
          page: @pagy.page,
          count: @pagy.count,
          items: @pagy.items,
          pages: @pagy.pages
        }
      }, status: :ok
    else
      render json: { error: 'Influencer not found' }, status: :not_found
    end
  end

  # GET /social/raffles/live
  def live
    unless $redis.ping == 'PONG'
      render json: { message: 'Redis is not connected' }, status: :service_unavailable
      return
    end

    if params[:actions].nil? || params[:actions].is_a?(String) == false
      render json: { error: 'Actions parameter is required' }, status: :bad_request
      return
    end

    actions = {
      "PICTURE": "social_raffles_pending_pictures",
      "WINNERS": "social_raffles_pending_for_winners"
    }

    smembers = $redis.smembers(actions[params[:actions].to_sym])

    message = smembers.empty? ? 'No actions needed!' : 'Action needed!'

    render json: { data: smembers.map(&:to_i), action: params[:actions], message: message }, status: :ok
  end

  # GET /social/raffles/1
  def show
    render json: @social_raffle
  end

  # POST /social/raffles
  def create
    @social_raffle = Social::Raffle.new(social_raffle_params)

    if @social_raffle.save
      $redis.publish('social_raffles_live', @social_raffle.to_json)
      render json: @social_raffle, status: :created, location: @social_raffle
    else
      render json: @social_raffle.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /social/raffles/1/add_ad
  def add_ad
    @social_raffle = Social::Raffle.find(params[:id])
    ad = social_raffle_ad_params[:ad]

    if @social_raffle.update(ad: ad)

      render json: @social_raffle
    else
      render json: @social_raffle.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /social/raffles/1
  def update
    if @social_raffle.update(social_raffle_params)
      render json: @social_raffle
    else
      render json: @social_raffle.errors, status: :unprocessable_entity
    end
  end

  # DELETE /social/raffles/1
  def destroy
    @social_raffle.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_social_raffle
      @social_raffle = Social::Raffle.find(params[:id])
    end

    def social_raffle_ad_params
      params.permit(:ad)
    end

    # Only allow a list of trusted parameters through.
    def social_raffle_params
      params.require(:social_raffle).permit(:influencer_id, :title, :description, :start_date, :end_date, :status)
    end
end
