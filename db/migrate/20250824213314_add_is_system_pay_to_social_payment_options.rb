class AddIsSystemPayToSocialPaymentOptions < ActiveRecord::Migration[7.0]
  def change
    add_column :social_payment_options, :is_system_pay, :boolean, default: false
  end
end
