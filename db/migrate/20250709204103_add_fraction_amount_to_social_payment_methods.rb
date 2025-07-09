class AddFractionAmountToSocialPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    add_column :social_payment_methods, :fraction_amount, :float, default: 0.0
    add_column :social_payment_methods, :is_fractionated, :boolean, default: false
  end
end
