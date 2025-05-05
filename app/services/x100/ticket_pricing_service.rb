module X100
  class TicketPricingService
    class InvalidComboError < StandardError; end

    def self.final_amount(raffle, quantity, currency)
      validate_inputs(raffle, quantity, currency)

      exchange = Shared::Exchange.last
      rates = build_rates_hash(exchange)
      rate = get_rate_for_currency(rates, currency)

      base_total = calculate_base_total(raffle, quantity)
      (base_total * rate).round(2)
    end

    private_class_method

    def self.validate_inputs(raffle, quantity, currency)
      currencies = %w[VES COP USD]

      raise ArgumentError, "Quantity must be positive" unless quantity.positive?
      raise ArgumentError, "Invalid currency: '#{currency}'. Valid currencies: #{currencies.join(' ')}'" unless currencies.include?(currency.upcase)
    end

    def self.build_rates_hash(exchange)
      {
        ves: exchange.value_bs,
        cop: exchange.value_cop,
        usd: 1
      }
    end

    def self.get_rate_for_currency(rates, currency)
      rates[currency.downcase.to_sym] || raise(ArgumentError, "Unsupported currency: #{currency}")
    end

    def self.calculate_base_total(raffle, quantity)
      return quantity * raffle.price_unit if raffle.combos.blank?

      process_combos(raffle.combos, quantity, raffle.price_unit)
    end

    def self.process_combos(combos, quantity, unit_price)
      sorted_combos = combos.sort_by { |c| c["price"].to_f / c["quantity"].to_f }
      remaining = quantity
      total = 0.0

      sorted_combos.each do |combo|
        validate_combo(combo)
        qty = combo["quantity"].to_i
        price = combo["price"].to_f

        next if qty.zero? || remaining < qty

        count = remaining / qty
        total += count * price
        remaining %= qty
        break if remaining.zero?
      end

      total += remaining * unit_price if remaining.positive?
      total
    end

    def self.validate_combo(combo)
      unless combo["quantity"].present? && combo["price"].present?
        raise InvalidComboError, "Combo must contain quantity and price"
      end
    end
  end
end