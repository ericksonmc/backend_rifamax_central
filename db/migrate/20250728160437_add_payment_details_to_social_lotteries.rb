class AddPaymentDetailsToSocialLotteries < ActiveRecord::Migration[7.0]
  def change
    add_column :social_lotteries, :payment_details, :jsonb, default: {}
  end
end
