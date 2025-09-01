class BanksService
  def initialize
    @banks = [
      { "code": "0156", "value": "100% Banco", "label": "100% Banco" },
      { "code": "0172", "value": "Bancamiga", "label": "Bancamiga" },
      { "code": "0171", "value": "Banco Activo", "label": "Banco Activo" },
      { "code": "0175", "value": "Banco Bicentenario", "label": "Banco Bicentenario" },
      { "code": "0128", "value": "Banco Caroní", "label": "Banco Caroní" },
      { "code": "0164", "value": "Banco del microempresario", "label": "Banco del desarrollo del microempresario" },
      { "code": "0102", "value": "Banco de Venezuela", "label": "Banco de Venezuela" },
      { "code": "0114", "value": "Bancaribe", "label": "Bancaribe" },
      { "code": "0163", "value": "Banco del Tesoro", "label": "Banco del Tesoro" },
      { "code": "0115", "value": "Banco Exterior", "label": "Banco Exterior" },
      { "code": "0105", "value": "Mercantil", "label": "Mercantil" },
      { "code": "0191", "value": "Banco Nacional de Crédito", "label": "Banco Nacional de Crédito" },
      { "code": "0116", "value": "Banco Occidental de Descuento", "label": "Banco Occidental de Descuento" },
      { "code": "0138", "value": "Banco Plaza", "label": "Banco Plaza" },
      { "code": "0108", "value": "Provincial", "label": "Provincial" },
      { "code": "0104", "value": "Venezolano de Crédito", "label": "Venezolano de Crédito" },
      { "code": "0168", "value": "Bancrecer", "label": "Bancrecer" },
      { "code": "0134", "value": "Banesco", "label": "Banesco" },
      { "code": "0177", "value": "Banfanb", "label": "Banfanb" },
      { "code": "0174", "value": "Banplus", "label": "Banplus" },
      { "code": "0157", "value": "Delsur Banco Universal", "label": "Delsur Banco Universal" },
      { "code": "0151", "value": "Banco Fondo Común", "label": "Banco Fondo Común" },
      { "code": "0169", "value": "Mibanco", "label": "Mibanco" },
      { "code": "0137", "value": "Sofitasa", "label": "Sofitasa" }
    ]
  end

  def find_bank(target_value)
    if @banks.empty?
      raise "No banks available"
    end
 
    if target_value.nil? || target_value.empty?
      raise "Target value cannot be nil or empty"
    end

    bank = @banks.find { |b| b[:value] == target_value }

    if bank.nil?
      raise "Bank with value '#{target_value}' not found"
    end

    bank
  rescue StandardError => e
    Rails.logger.error("Error finding bank: #{e.message}")
    raise "An error occurred while finding the bank: #{e.message}"  
  end
end