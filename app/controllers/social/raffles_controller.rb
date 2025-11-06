class Social::RafflesController < ApplicationController
  include Pagy::Backend

  before_action :set_social_raffle_by_custom_link, only: %i[ filter_by_custom_link ]
  before_action :set_social_raffle, only: %i[ show update destroy set_combos toggle_fractions ]
  before_action :authorize_request, only: %i[ index list_dashboard profit_dashboard create update destroy only_influencers only_lotteries add_content confirm reject ]
  before_action :only_lotteries, only: %i[confirm reject]
  before_action :only_influencers, only: %i[add_content]
  
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

  # GET /social/raffles/info/{custom_link}
  def info
    @raffle_custom = Social::Raffle.find_by(custom_link: params[:custom_link])
    if @raffle_custom
      render json: @raffle_custom, status: :ok
    else
      render json: { error: 'Raffle not found' }, status: :not_found
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

  # GET /social/raffles/{id}
  def show
    render json: @social_raffle, status: :ok
  end

  # GET /social/raffles/filter_by_custom_link/{custom_link}
  def filter_by_custom_link
    render json: @raffle, status: :ok
  end

  # POST /social/raffles/pay_app
  def pay_app
    raffle = Social::Raffle.find_by(id: pay_app_params[:social_raffle_id])
    return render json: { message: 'Raffle not found' }, status: :not_found unless raffle

    details = pay_app_params[:details]
    payment_type = pay_app_params[:payment_type]

    if details.blank? || payment_type.blank?
      return render json: { message: 'Missing payment details or type' }, status: :unprocessable_entity
    end

    if raffle.pay_debt(details: details, payment: payment_type)
      render json: { message: 'Pago de deuda realizado exitosamente', raffle: raffle }, status: :ok
    else
      render json: { message: 'Error al notificar el pago', errors: raffle.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /social/raffles/pay_lottery_debt
  def pay_lottery_debt
    raffle = Social::Raffle.find_by(id: pay_app_params[:social_raffle_id])
    return render json: { message: 'Raffle not found' }, status: :not_found unless raffle

    details = pay_app_params[:details]
    payment_type = pay_app_params[:payment_type]

    if details.blank? || payment_type.blank?
      return render json: { message: 'Missing payment details or type' }, status: :unprocessable_entity
    end

    if raffle.pay_lottery_debt(details: details, payment: payment_type)
      render json: { message: 'Pago de deuda realizado exitosamente', raffle: raffle }, status: :ok
    else
      render json: { message: 'Error al notificar el pago', errors: raffle.errors.full_messages }, status: :unprocessable_entity
    end
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
    @social_raffle.custom_link = @social_raffle.title.parameterize

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

  # PATCH/PUT /social/raffles/{id}/add_documents
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

  # PATCH/PUT /social/raffles/{id}
  def update
    if @social_raffle.update(social_raffle_params)
      render json: @social_raffle
    else
      render json: @social_raffle.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /social/raffles/{id}/toggle_fractions
  def toggle_fractions
    if @social_raffle.update(fractions: !@social_raffle.allow_fractions)
      render json: @social_raffle, status: :ok
    else
      render json: @social_raffle.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /social/raffles/{id}/set_combos
  def set_combos
    if @social_raffle.update(combos_params)
      render json: @social_raffle
    else
      render json: @social_raffle.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /social/raffles/{id}/add_content
  def add_content
    @social_raffle = Social::Raffle.find(params[:id])

    if @social_raffle.update(content: add_content_params[:content])
      render json: @social_raffle, status: :ok
    else
      render json: @social_raffle.errors, status: :unprocessable_entity
    end
  end

  # DELETE /social/raffles/{id}
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
  
  def only_influencers
    unless @current_user.Influencer?
      render json: { error: 'Only influencers can perform this action' }, status: :forbidden
      return
    end
  end

  def set_social_raffle
    @social_raffle = Social::Raffle.find(params[:id])
  end

  def set_social_raffle_by_custom_link
    @raffle = Social::Raffle.find_by(custom_link: params[:custom_link])
  end

  def ad_params
    params.permit(:ad, :rif, :dni, :bank_register, receipts: [])
  end

  def pay_app_params
    params.require(:social_payment_method).permit(
      :social_raffle_id,
      :payment_type,
      details: [:bank, :name, :last_digits, :payment_date, :phone, :email, :reference]
    )
  end

  def add_content_params
    params.permit(
      :content
    )
  end

  def combos_params
    params.require(:social_raffle).permit(
      combo: [:quantity, :value]
    )
  end

  def social_raffle_params
    params.require(:social_raffle).permit(
      :title,
      :init_date,
      :price_unit,
      :expired_date,
      :has_credit,
      :min_ticket_buy,
      :tickets_count,
      :social_lottery_id,
      :social_influencer_id,
      prizes: [:name, :worth, :prize_position]
    )
  end
end
