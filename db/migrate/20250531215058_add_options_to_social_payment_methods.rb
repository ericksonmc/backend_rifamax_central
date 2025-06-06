class AddOptionsToSocialPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    add_column :social_payment_methods, :email_send, :boolean, default: :false
    add_column :social_payment_methods, :whatsapp_send, :boolean, default: :false
  end
end
