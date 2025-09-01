class AddFractionDebtToSocialPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    add_column :social_payment_methods, :fraction_debt, :float, default: 0.0
    add_column :social_payment_methods, :fraction_id, :bigint
  end
end
