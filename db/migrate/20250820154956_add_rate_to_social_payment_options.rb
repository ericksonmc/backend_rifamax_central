class AddRateToSocialPaymentOptions < ActiveRecord::Migration[7.0]
  def change
    add_column :social_payment_options, :rate, :float, default: 1.0
  end
end
