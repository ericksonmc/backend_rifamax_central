class Social::RafflesController < ApplicationController
  include Pagy::Backend

  before_action :set_social_raffle, only: %i[ show update destroy ]
  before_action :authorize_request, only: %i[ index show list_dashboard profit_dashboard create update destroy only_lotteries confirm reject ]
  before_action :only_lotteries, only: %i[confirm reject]
  
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
      @raffles = influencer.to_sell
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

  # GET /social/raffles/pendings?content_code={content_code}&count={count}&page={page}
  def pendings
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

  # GET /social/raffles/list_dashboard
  def list_dashboard
    influencer = @current_user.social_influencer
    @lottery = Social::Lottery.find_by(shared_user_id: @current_user.id)

    count = params[:count] || 10
    page = params[:page] || 1

    @raffles = case @current_user.role
    when 'Influencer'
      influencer.ongoing_raffles
    when 'Admin'
      Social::Raffle.all
    when 'Loteria'
      Social::Raffle.where(social_lottery_id: @lottery.id)
    else
      []
    end

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
  end

  # GET /social/raffles/profit_dashboard
  def profit_dashboard
    raffle_id = params[:raffle_id]
    finder = params[:finder] || 'general'

    case finder
    when 'general'
      result = Social::Raffle.all_profits(@current_user)

      render json: result, status: :ok
    when 'specific'
      @raffle = Social::Raffle.find(raffle_id)
      return render json: { message: 'Raffle not found' }, status: :not_found if @raffle.nil?

      render json: @raffle.profits, status: :ok
    else
      render json: { message: 'Finder not found' }, status: :not_found
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

   # POST /social/raffles/confirm
  def confirm
    @raffle = Social::Raffle.find_by(id: params[:raffle_id])
    unless @raffle
      render json: { message: "Raffle not found" }, status: :not_found and return
    end
  
    if @raffle.update(confirmation: true)
      render json: { message: 'Raffle confirmed!', raffle: @raffle }, status: :ok
    else
      render json: { message: 'Failed to confirm raffle', errors: @raffle.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # POST /social/raffles/reject
  def reject
    @raffle = Social::Raffle.find_by(id: params[:raffle_id])
    @rejecting_details = params[:message]

    unless @raffle
      render json: { message: "Raffle not found" }, status: :not_found and return
    end
  
    if @raffle.update(rejecting_details: @rejecting_details)
      render json: { message: 'Raffle rejected!', raffle: @raffle }, status: :ok
    else
      render json: { message: 'Failed to reject raffle', errors: @raffle.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /social/raffles
  def create
    @social_raffle = Social::Raffle.new(social_raffle_params)

    if @current_user.Loteria?
      @social_raffle.social_lottery_id = Social::Lottery.find_by(shared_user_id: @current_user.id).id
      @social_raffle.confirmation = true
    end

    if @current_user.Influencer?
      @social_raffle.social_influencer_id = @current_user.social_influencer.id
    end

    if @social_raffle.save
      ActionCable.server.broadcast("social_raffles_incoming_#{@current_user.id}", Social::Raffle.raffle_emergents_count(@current_user))
      $redis.publish('social_raffles_live', @social_raffle.to_json)
      $redis.set("social_sold_serie:#{@social_raffle.id}", [])
      render json: @social_raffle, status: :created, location: @social_raffle
    else
      render json: @social_raffle.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /social/raffles/1/add_documents
  def add_documents
    @social_raffle = Social::Raffle.find(params[:id])
    new_receipts = params[:receipts]&.values || [] 

    if @social_raffle.update(
      ad: ad_params[:ad],
      rif: ad_params[:rif],
      dni: ad_params[:dni],
      bank_register: ad_params[:bank_register],
      receipts: new_receipts
    )
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

  def only_lotteries
    unless @current_user.Loteria?
      render json: { error: 'Only lotteries can perform this action' }, status: :forbidden
      return
    end
  end

  def set_social_raffle
    @social_raffle = Social::Raffle.find(params[:id])
  end

  def ad_params
    params.permit(:ad, :rif, :dni, :bank_register, receipts: [])
  end

  def social_raffle_params
    params.require(:social_raffle).permit(
      :title,
      :init_date,
      :price_unit,
      :expired_date,
      :has_credit,
      :tickets_count,
      :social_lottery_id,
      :social_influencer_id,
      prizes: [:name, :worth, :prize_position]
    )
  end
end
