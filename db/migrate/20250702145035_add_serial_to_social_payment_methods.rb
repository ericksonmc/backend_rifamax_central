class AddSerialToSocialPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    add_column :social_payment_methods, :serial, :string
    add_index :social_payment_methods, :serial, unique: true
  end
end