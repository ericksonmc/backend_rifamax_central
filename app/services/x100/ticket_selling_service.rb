module X100
  class TicketSellingService
    class TicketStateError < StandardError; end
    class UserNotFoundError < StandardError; end
    class TicketSellingError < StandardError; end
    class ClientNotFoundError < StandardError; end
    class RaffleNotFoundError < StandardError; end
    class InvalidPositionsError < StandardError; end
    class TicketValidationError < StandardError; end
    class InvalidCurrenciesError < StandardError; end
    class InvalidParametersError < StandardError; end
    class InsufficientFundsError < StandardError; end
    class TicketCountMismatchError < StandardError; end
    class IntegrationJobIsDownError < StandardError; end
    class TicketsAreNotReservedError < StandardError; end
    class OperationNotInmutableError < StandardError; end
    class IntegrationClientNotFoundError < StandardError; end

    def self.sell(products:, money:, raffle:, client_id:, user:)
      validate_user(user)
      validate_raffle(raffle)
      validate_client(client_id)
      validate_currencies(money)

      ActiveRecord::Base.transaction do
        process_sell(
          money: money,
          raffle: raffle,
          products: products,
          client_id: client_id,
          integrator_type: nil
        )
        process_order(
          user: user,
          money: money,
          raffle: raffle,
          products: products,
          client_id: client_id,
        )
      end
    rescue => e
      raise TicketSellingError, "Unexpected error happens: #{e}"
    end

    def self.sell_via_integrator(products:, money:, raffle:, integrator_id:, integrator_type:, user:)
      validate_user(user)
      validate_raffle(raffle)
      validate_currencies(money)
      validate_integrator_client(integrator_id, integrator_type)
      validate_sufficient_funds_before_tx(integrator_id, money, X100::TicketPricingService.final_amount(raffle, products.length, money))
      
      ActiveRecord::Base.transaction do
        process_sell(
          money: money,
          raffle: raffle,
          products: products,
          client_id: integrator_id,
          integrator_type: integrator_type
        )
        integration_consumer(raffle, integrator_id, integrator_type, products, money)
        integration_process_order(
          user: user,
          money: money,
          raffle: raffle,
          products: products,
          client_id: integrator_id,
          integrator_id: integrator_id.to_i,
          integrator_type: integrator_type.to_s
        ) 
      end
    rescue => e
      raise TicketSellingError, "Unexpected error happens: #{e}"
    end

    private_class_method

    def self.generate_order_serial
      "ORD-#{SecureRandom.hex(8).upcase}"
    end

    def self.find_client(client_id, integrator_type)
      integrator_types = ['CDA']

      if integrator_types.include?(integrator_type)
        X100::Client.find_by(integrator_id: client_id, integrator_type: integrator_type)
      else
        X100::Client.find(client_id)
      end
    end

    def self.process_sell(products:, money:, raffle:, client_id:, integrator_type:)
      raise ArgumentError, "Products must be an array" unless products.is_a?(Array)
      
      client = find_client(client_id, integrator_type)

      tickets = X100::Ticket.lock
        .where(x100_raffle_id: raffle.id, position: products)
        .order(:id)
    
      missing_positions = products - tickets.pluck(:position)
      unless missing_positions.empty?
        raise TicketNotFoundError.new(
          "Positions not found: #{missing_positions.join(', ')}"
        )
      end
    
      unit_price = X100::TicketPricingService.final_amount(raffle, 1, money)
    
      sold_count = 0
      X100::Ticket.transaction do
        tickets.each do |ticket|
          begin
            ticket.sell!
            ticket.update!(
              money: money,
              x100_client_id: client.id,
              price: unit_price,
              serial: SecureRandom.uuid()
            )
            sold_count += 1
          rescue AASM::InvalidTransition => e
            raise TicketStateError.new(
              "Ticket #{ticket.position} invalid state: #{ticket.status}"
            )
          rescue ActiveRecord::RecordInvalid => e
            raise TicketValidationError.new(
              "Ticket #{ticket.position} invalid: #{e.record.errors.full_messages}"
            )
          end
        end
    
        unless sold_count == products.size
          raise TicketCountMismatchError.new(
            "Requested #{products.size} tickets, sold #{sold_count}"
          )
        end
    
        X100::BroadcastingService.refresh
      end
    
      tickets.pluck(:position)
    rescue => e
      Rails.logger.error "Ticket sell failed: #{e.message}"
      raise
    end

    def self.process_order(products:, raffle:, client_id:, user:, money:)
      amount = X100::TicketPricingService.final_amount(raffle, products.length, money)

      order = X100::Order.new(
        products: products,
        amount: amount,
        serial: generate_order_serial(),
        ordered_at: Time.current,
        money: money,
        shared_user_id: user.id,
        shared_exchange_id: Shared::Exchange.last.id,
        x100_raffle_id: raffle.id,
        x100_client_id: client_id,
      )

      raise TicketSellingError.new "Error trying to generate order" unless order.save

      add_sold_to_list(raffle, products)

      return order
    end

    def self.integration_process_order(products:, raffle:, client_id:, user:, money:, integrator_type:, integrator_id:)
      client = find_client(client_id, integrator_type)
      
      amount = X100::TicketPricingService.final_amount(raffle, products.length, money)
      
      order = X100::Order.new(
        products: products,
        amount: amount,
        serial: generate_order_serial(),
        ordered_at: Time.current,
        money: money,
        shared_user_id: user.id,
        shared_exchange_id: Shared::Exchange.last.id,
        # integrator: integrator_type.to_s,
        # integrator_player_id: integrator_id.to_i,
        x100_raffle_id: raffle.id,
        x100_client_id: client.id
      )

      raise TicketSellingError.new "Error trying to generate order" unless order.valid?

      order.save!

      add_sold_to_list(raffle, products)

      return order
    end

    def self.validate_integrator_client(x100_client_id, integrator_type)
      existant_client = X100::Client.exists?(integrator_id: x100_client_id, integrator_type: integrator_type)
      
      return if existant_client

      raise IntegrationClientNotFoundError.new "Integration client not found or doesn't exist"
    end

    def self.validate_client(x100_client_id)
      existant_client = X100::Client.exists?(id: x100_client_id)
      
      return if existant_client

      raise ClientNotFoundError.new "Client not found or doesn't exist"
    end

    def self.add_sold_to_list(raffle, products)
      products.each do |product|
        product_parsed = product.to_s.rjust(4, '0')
    
        data = {
          position: product_parsed,
          serial: SecureRandom.uuid,
          price: nil,
          money: nil,
          status: 'available'
        }
    
        serie_sold = eval($redis.get("sold_serie:#{raffle.id}")).excluding(product)
    
        $redis.hset("serie:#{raffle.id}", product_parsed, data.to_json)
        $redis.set("sold_serie:#{raffle.id}", serie_sold)
      end
    end

    def self.validate_sufficient_funds_before_tx(player_id, currency, amount)
      url = "#{ENV['cda_url_base']}/wallets_rifas?player_id=#{player_id}&currency=#{currency}"

      response = HTTParty.get(url)

      raise InsufficientFundsError.new "Insufficient funds in account, please recharge before play." if JSON.parse(response.body)["balance"].to_f < amount
    end

    def self.validate_currencies(currency)
      currencies_allowed = %w[USD VES COP]

      raise InvalidCurrenciesError.new "Currency '#{currency}' is not allowed, currencies available: #{currencies_allowed}" unless currencies_allowed.include?(currency)
    end
    
    def self.validate_user(user)
      user_exists = Shared::User.exists?(user.id)
    
      raise UserNotFoundError.new("User not found") unless user_exists
    end

    def self.validate_raffle(raffle)
      raffle_exists = X100::Raffle.exists?(raffle.id)
    
      raise RaffleNotFoundError.new("Raffle not found") unless raffle_exists
    end

    def self.integration_consumer(raffle, client_id, integrator_type, products, money)
      client = find_client(client_id, integrator_type)
      raise ClientNotFoundError.new "Client not found" if client.nil?

      tickets = X100::Ticket.where(x100_raffle_id: raffle.id, position: products)
      raise TicketNotFoundError.new 'Not tickets found' if tickets.empty?

      parse_tickets = tickets.map do |ticket|
        {
          id: ticket.id, 
          position: ticket.position, 
          serial: ticket.serial, 
          price: ticket.price, 
          money: ticket.money, 
          status: ticket.status,
        }
      end

      url = "#{ENV['cda_url_base']}/wallets_rifas/debit"
    
      payload =  {
        amount: X100::TicketPricingService.final_amount(raffle, products.length, money),
        serial: generate_order_serial(),
        tickets: parse_tickets,
        tx_transaction: 'DEBIT',
        currency: money,
        player_id: client_id,
        x100_raffle: {
          raffle_image: "#{ENV['url_base']}/#{raffle.ad.url}",
          title: raffle.title,
          status: raffle.status,
          money: raffle.money,
          raffle_type: raffle.raffle_type,
          price_unit: raffle.price_unit,
          tickets_count: raffle.tickets_count,
          lotery: raffle.lotery,
          draw_type: raffle.draw_type,
          expired_date: raffle.expired_date == nil ? nil : raffle.expired_date.strftime("%d/%m/%Y - %H:%M"),
        }
      }

      response = HTTParty.post(url, body: payload.to_json, headers: { 'Content-Type' => 'application/json' })
      
      raise IntegrationJobIsDownError.new({ 
        message: "Integration is down",
        code: response.code,
        res: response.response,
        headers: response.headers
      }) unless response.code == 200
    end
  end
end