class AddTicketsToSocialPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    add_column :social_payment_methods, :tickets, :integer, array: true, default: []
  end
end
