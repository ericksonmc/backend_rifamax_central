class AddFractionAmountToSocialPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    add_column :social_payment_methods, :fly_amounts, :float, array: true, default: []
    add_column :social_payment_methods, :has_fly_amount, :boolean, default: false
    add_column :social_payment_methods, :fractions, :integer, default: 1
    add_column :social_payment_methods, :is_fractionated, :boolean, default: false
  end
end
