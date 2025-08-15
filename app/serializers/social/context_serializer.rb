# == Schema Information
#
# Table name: social_contexts
#
#  id         :bigint           not null, primary key
#  context    :jsonb
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Social::ContextSerializer < ActiveModel::Serializer
  attributes :id, :key, :context

  def context
    return {} if object.context.nil?
  
    banks = [
      "100% Banco",
      "Bancamiga",
      "Banco Activo",
      "Banco Bicentenario",
      "Banco Caroní",
      "Banco del microempresario",
      "Banco de Venezuela",
      "Bancaribe",
      "Banco del Tesoro",
      "Banco Exterior",
      "Mercantil",
      "Banco Nacional de Crédito",
      "Banco Occidental de Descuento",
      "Banco Plaza",
      "Provincial",
      "Venezolano de Crédito",
      "Bancrecer",
      "Banesco",
      "Banfanb",
      "Banplus",
      "Delsur Banco Universal",
      "Banco Fondo Común",
      "Mibanco",
      "Sofitasa"
    ]

    today_rate = 136.89

    raffle_id = object.context['raffle_id']
    tickets_quantity = object.context['tickets_quantity'].to_i
  
    amount = nil
    if raffle_id.present? && tickets_quantity > 0
      raffle = Social::Raffle.find_by(id: raffle_id)
      amount = raffle&.amount.to_f * tickets_quantity if raffle
    end
  
    amount_in_ves = amount.nil? ? nil : amount.to_f * today_rate
  
    object.context.merge(available_banks: banks)
      .merge(today_rate: today_rate)
      .merge(amount_in_ves: amount_in_ves)
  end
end
