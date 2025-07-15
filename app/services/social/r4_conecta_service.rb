# frozen_string_literal: true

# app/services/social/r4_conecta_service.rb
require 'faraday'
require 'openssl'
require 'json'
require 'nokogiri'
require 'open-uri'

class Social::R4ConectaService
  API_METHODS = {
    r4bcv:                   '/R4bcv',
    r4consulta:              '/R4consulta',
    r4notifica:              '/R4notifica',
    r4pagos:                 '/R4pagos',
    r4vuelto:                '/R4vuelto',
    generar_otp:             '/GenerarOtp',
    debito_inmediato:        '/DebitoInmediato',
    consultar_operaciones:   '/ConsultarOperaciones',
    domiciliacion_cnta:      '/TransferenciaOnline/DomiciliacionCNTA',
    domiciliacion_cele:      '/TransferenciaOnline/DomiciliacionCELE',
    credito_inmediato:       '/CreditoInmediato',
    ciclo_cuentas:           '/CICuentas',
    c2p:                     '/R4c2p',
    anulacion_c2p:           '/R4anulacionC2P'
  }.freeze

  def initialize
    @base_url                 = ENV.fetch('R4_CONECTA_BASE_URL')
    @commerce                 = ENV.fetch('R4_CONECTA_COMMERCE')
    @commerce_id              = ENV.fetch('R4_CONECTA_COMMERCE_ID')
    @commerce_phone           = ENV.fetch('R4_CONECTA_COMMERCE_PHONE')
    @log_sensitive            = ENV.fetch('R4_CONECTA_LOG_SENSITIVE', 'false') == 'true'
    @default_currency         = ENV.fetch('R4_CONECTA_DEFAULT_CURRENCY', 'USD').upcase # availables currencies: ['USD' 'EUR' 'RUB' 'TRY' 'CNY']
    @now                      = Time.now.strftime('%Y-%m-%d') # default format -> yyyy-mm-dd
    @logger                   = Logger.new(ENV.fetch('R4_CONECTA_LOG_PATH', 'log/r4_conecta.log'))
    @success_codes            = [200, 201, 202, 204] # HTTP success codes
  end

  def consultar_tasa_bcv(moneda: @default_currency, fechavalor: @now)
    payload = { 'Moneda' => moneda, 'Fechavalor' => fechavalor }
    call_api(:r4bcv, payload)
  end

  def consulta_cliente(id_cliente: @commerce_id, monto:, telefono_comercio: @commerce_phone)
    payload = {
      'IdCliente'       => id_cliente,
      'Monto'           => monto.to_s,
      'TelefonoComercio'=> telefono_comercio
    }
    call_api(:r4consulta, payload)
  end

  def notificar_pago(params)
    payload = {
      'IdComercio'       => @commerce_id,
      'TelefonoComercio' => @commerce_phone,
      'TelefonoEmisor'   => params[:telefono_emisor],
      'Concepto'         => params[:concepto] || '',
      'BancoEmisor'      => params[:banco_emisor],
      'Monto'            => params[:monto],
      'FechaHora'        => params[:fecha_hora],
      'Referencia'       => params[:referencia],
      'CodigoRed'        => params[:codigo_red]
    }
    call_api(:r4notifica, payload)
  end

  def gestionar_pagos(monto:, fecha:, referencia:, personas:)
    payload = {
      'monto'     => monto,
      'fecha'     => fecha,
      'Referencia'=> referencia,
      'personas'  => personas
    }
    call_api(:r4pagos, payload)
  end

  def obtener_vuelto(telefono_destino:, cedula:, banco:, monto:, concepto: nil, ip: nil)
    payload = {
      'TelefonoDestino' => telefono_destino,
      'Cedula'          => cedula,
      'Banco'           => banco,
      'Monto'           => monto,
      'Concepto'        => concepto || 'Vuelto',
      'Ip'              => ip
    }.compact
    call_api(:r4vuelto, payload)
  end

  def generar_otp(banco:, monto:, telefono:, cedula:)
    payload = { 'Banco' => banco, 'Monto' => monto, 'Telefono' => telefono, 'Cedula' => cedula }
    call_api(:generar_otp, payload)
  end

  def debito_inmediato(banco:, monto:, telefono:, cedula:, nombre:, otp:, concepto:)
    payload = {
      'Banco'   => banco,
      'Monto'   => monto,
      'Telefono'=> telefono,
      'Cedula'  => cedula,
      'Nombre'  => nombre,
      'OTP'     => otp,
      'Concepto'=> concepto
    }
    call_api(:debito_inmediato, payload)
  end

  def consultar_operaciones(id:)
    payload = { 'Id' => id }
    call_api(:consultar_operaciones, payload)
  end

  def domiciliar_cuenta(doc_id:, nombre:, cuenta:, monto:, concepto:)
    payload = {
      'docId'   => doc_id,
      'nombre'  => nombre,
      'cuenta'  => cuenta,
      'monto'   => monto,
      'concepto'=> concepto
    }
    call_api(:domiciliacion_cnta, payload)
  end

  def domiciliar_por_telefono(doc_id:, telefono:, nombre:, banco:, monto:, concepto:)
    payload = {
      'docId'   => doc_id,
      'telefono'=> telefono,
      'nombre'  => nombre,
      'banco'   => banco,
      'monto'   => monto,
      'concepto'=> concepto
    }
    call_api(:domiciliacion_cele, payload)
  end

  def credito_inmediato_por_telefono(banco:, cedula:, telefono:, monto:, concepto:)
    payload = {
      'Banco'   => banco,
      'Cedula'  => cedula,
      'Telefono'=> telefono,
      'Monto'   => monto,
      'Concepto'=> concepto
    }
    call_api(:credito_inmediato, payload)
  end

  def credito_inmediato_por_cuenta(cedula:, cuenta:, monto:, concepto:)
    payload = {
      'Cedula'  => cedula,
      'Cuenta'  => cuenta,
      'Monto'   => monto,
      'Concepto'=> concepto
    }
    call_api(:ciclo_cuentas, payload)
  end

  def cobrar_c2p(telefono_destino:, cedula:, concepto:, banco:, ip:, monto:, otp:)
    payload = {
      'TelefonoDestino'=> telefono_destino, 
      'Cedula'         => cedula,
      'Concepto'       => concepto,
      'Banco'          => banco,
      'Ip'             => ip,
      'Monto'          => monto,
      'Otp'            => otp
    }
    call_api(:c2p, payload)
  end

  def anular_c2p(cedula:, banco:, referencia:)
    payload = { 'Cedula' => cedula, 'Banco' => banco, 'Referencia' => referencia }
    call_api(:anulacion_c2p, payload)
  end

  private

  def call_api(method_key, payload)
    url     = "#{@base_url}#{API_METHODS.fetch(method_key)}"
    token   = generate_token(method_key, payload)
    headers = {
      'Content-Type'  => 'application/json',
      'Authorization' => token,
      'Commerce'      => @commerce
    }
  
    log_request(method_key, payload, url, headers)
    response = Faraday.post(url, payload.to_json, headers)
    
    error_message = "API call failed with status #{response.status}: #{response.body}"
    @logger.error("[#{method_key.upcase}] ERROR: #{error_message}") unless @success_codes.include?(response.status)
    
    begin
      parsed = JSON.parse(response.body)
      curr_time = Date.today
      payment_date = Date.parse(payload['Fechavalor'])
      
      if (payment_date == curr_time && method_key == :r4bcv && parsed['message'] == "Cotización no encontrada")
        last_day_response = Faraday.post(url, payload.merge('Fechavalor' => (curr_time - 1.day).strftime('%Y-%m-%d')).to_json, headers)
        last_day_parsed = JSON.parse(last_day_response.body)

        @logger.warn("[#{method_key.upcase}] WARNING: Cotización no encontrada, usando valor de dolar anterior: #{curr_time}}")
        return last_day_parsed if @success_codes.include?(last_day_response.status)
      end
    rescue JSON::ParserError
      if response.status == 404
        return { error: 'Not found', status: 404 }
      else
        raise
      end
    end
  
    log_response(method_key, parsed)
    parsed
  rescue StandardError => e
    @logger.error("[#{method_key.upcase}] ERROR: #{e.class} – #{e.message}")
    raise
  end

  def generate_token(method_key, payload)
    data = case method_key
           when :r4bcv
             "#{payload['Fechavalor']}#{payload['Moneda']}"
           when :r4pagos
             "#{payload['monto']}#{payload['fecha']}"
           else
             payload.values.join
           end

    OpenSSL::HMAC.hexdigest('SHA256', @commerce, data)
  end

  def log_request(key, payload, url, headers)
    safe_payload = @log_sensitive ? payload : obfuscate(payload)
    @logger.info("[#{key.upcase}] ▶ URL: #{url}")
    @logger.info("[#{key.upcase}] ▶ Req-Hdr: #{headers}")
    @logger.info("[#{key.upcase}] ▶ Req-Body: #{safe_payload}")
  end

  def log_response(key, resp)
    safe_resp = @log_sensitive ? resp : obfuscate(resp)
    @logger.info("[#{key.upcase}] ◀ Resp: #{safe_resp}")
  end

  def obfuscate(obj)
    case obj
    when Hash
      obj.transform_values { |v| obfuscate(v) }
    when Array
      obj.map { |v| obfuscate(v) }
    when String
      obj.length > 4 ? '*' * (obj.length - 4) + obj[-4..] : obj
    else
      obj
    end
  end
end
