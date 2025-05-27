class CreateSocialFees < ActiveRecord::Migration[7.0]
  def change
    create_table :social_fees do |t|
      t.float :admin_profit_fee

      t.timestamps
    end
  end
end
