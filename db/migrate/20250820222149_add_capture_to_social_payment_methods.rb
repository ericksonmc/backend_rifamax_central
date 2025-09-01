class AddCaptureToSocialPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    add_column :social_payment_methods, :capture, :string
    add_column :social_payment_methods, :payment_option, :integer, default: 0
  end
end
