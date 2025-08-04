class Social::WaWebhookController < ApplicationController
  before_action :validates_token_presence

  def create
    $redis.set("wa_evo_webhook", params[:phone])

    render json: { status: true }, status: :ok
  end

  private

  def validates_token_presence
    @token = request.headers['WA_ACCESS_TOKEN']

    if @token.nil?
      render json: { message: 'Token not found' }, status: :not_found and return
    end

    unless @token === ENV['WA_ACCESS_TOKEN']
      render json: { message: 'Token missmatch' }, status: :forbidden and return
    end
  end
end
