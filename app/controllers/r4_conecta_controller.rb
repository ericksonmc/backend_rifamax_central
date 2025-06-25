class R4ConectaController < ApplicationController
  before_action :validate_bank_signature
  
  def handshake
    @bank_signature_uuid = ENV.fetch('BANK_SIGNATURE_UUID', nil)
    @header_signature_uuid = request.headers['Authorization'].to_s
    @commerce_phone = ENV.fetch('R4_CONECTA_COMMERCE_PHONE', nil)

    id_client = handshake_params[:idCliente]
    monto = handshake_params[:Monto]
    telefono_comercio = handshake_params[:TelefonoComercio]

    token_valid = @bank_signature_uuid == @header_signature_uuid

    phone_commerce_valid = @commerce_phone.present? && telefono_comercio == @commerce_phone

    params_valid = id_client.present? && phone_commerce_valid

    return render json: { error: 'Not found' }, status: :not_found unless token_valid

    render json: { status: params_valid }, status: params_valid ? :ok : :unprocessable_entity
  end

  def notification
    @bank_signature_uuid = ENV.fetch('BANK_SIGNATURE_UUID', nil)
    @header_signature_uuid = request.headers['Authorization'].to_s
    @commerce_id = ENV.fetch('R4_CONECTA_COMMERCE_ID', nil)
    @commerce_phone = ENV.fetch('R4_CONECTA_COMMERCE_PHONE', nil)

    id_comercio = notification_params[:idComercio]
    telefono_comercio = notification_params[:TelefonoComercio]
    telefono_emisor = notification_params[:TelefonoEmisor]
    concepto = notification_params[:Concepto]
    banco_emisor = notification_params[:BancoEmisor]
    monto = notification_params[:Monto]
    fecha_hora = Date.parse(notification_params[:FechaHora]).strftime('%Y-%m-%d')
    referencia = notification_params[:Referencia]
    codigo_red = notification_params[:CodigoRed]

    phone_commerce_valid = @commerce_phone.present? && telefono_comercio == @commerce_phone
    commerce_id_valid = @commerce_id.present? && id_comercio == @commerce_id
    
    token_valid = @bank_signature_uuid == @header_signature_uuid
    
    commerce_valid = phone_commerce_valid && commerce_id_valid && token_valid

    return render json: { error: 'Not found' }, status: :not_found unless commerce_valid
    
    transaction_valid = codigo_red == '00'

    $redis.set("R4:#{telefono_emisor}:#{referencia}:#{banco_emisor}:#{fecha_hora}", monto) if transaction_valid

    render json: { abono: transaction_valid }, status: transaction_valid ? :ok : :unprocessable_entity
  end

  private

  def handshake_params
    params.permit(:idCliente, :Monto, :TelefonoComercio)
  end

  def notification_params
    params.permit(
      :idComercio, 
      :TelefonoComercio,
      :TelefonoEmisor,
      :Concepto,
      :BancoEmisor,
      :Monto,
      :FechaHora,
      :Referencia,
      :CodigoRed
    )
  end

  def validate_bank_signature
    @bank_signature_uuid = ENV.fetch('BANK_SIGNATURE_UUID', nil)

    if @bank_signature_uuid.nil?
      render json: { error: 'Bank signature UUID is not configured' }, status: :unprocessable_entity
    end
  end
end