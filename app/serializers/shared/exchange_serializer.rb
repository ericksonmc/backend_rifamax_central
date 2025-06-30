class Shared::ExchangeSerializer < ActiveModel::Serializer
  attributes :id, :value_bs, :value_cop, :mainstream_money, :automatic, :created_at, :updated_at

  def value_bs
    Shared::Exchange.get_bsd
  end

  def created_at
    object.created_at&.strftime('%Y-%m-%d %H:%M:%S')
  end

  def updated_at
    object.created_at&.strftime('%Y-%m-%d %H:%M:%S')
  end
end
