class R4ConectaController < ApplicationController
  before_action :validate_bank_signature
  
  def handshake
    @bank_signature_uuid = ENV.fetch('BANK_SIGNATURE_UUID', nil)
    @header_signature_uuid = request.headers['Authorization'].to_s

    id_client = handshake_params[:idCliente]
    monto = handshake_params[:Monto]
    telefono_comercio = handshake_params[:TelefonoComercio]

    token_valid = @bank_signature_uuid == @header_signature_uuid
    puts "Bank Signature UUID: #{@bank_signature_uuid}"
    puts "Header Signature UUID: #{@header_signature_uuid}"
    puts "ID Cliente: #{id_client}"
    puts "Monto: #{monto}"
    puts "Telefono Comercio: #{telefono_comercio}"
    params_valid = id_client.present? && telefono_comercio.present?

    return render json: { error: 'Not found' }, status: :not_found unless token_valid

    if params_valid
      render json: { status: true }, status: :ok
    else
      render json: { status: false }, status: :unprocessable_entity
    end
  end

  def notification
    @notification_params = notification_params
    @bank_signature_uuid = ENV.fetch('BANK_SIGNATURE_UUID', nil)
    @header_signature_uuid = request.headers['Authorization'].to_s
  
    token_valid = @bank_signature_uuid == @header_signature_uuid
  
    render json: { status: token_valid }, status: token_valid ? :ok : :unprocessable_entity
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