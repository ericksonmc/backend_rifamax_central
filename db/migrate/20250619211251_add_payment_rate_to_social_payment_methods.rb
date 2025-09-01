class AddPaymentRateToSocialPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    add_column :social_payment_methods, :payment_rate, :float
  end
end
