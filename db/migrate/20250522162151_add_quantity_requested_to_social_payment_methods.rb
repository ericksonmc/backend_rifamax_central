class AddQuantityRequestedToSocialPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    add_column :social_payment_methods, :quantity_requested, :integer
  end
end
