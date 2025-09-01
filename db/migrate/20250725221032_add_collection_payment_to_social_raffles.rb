class AddCollectionPaymentToSocialRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :social_raffles, :collection_payment, :jsonb, default: {}
  end
end
