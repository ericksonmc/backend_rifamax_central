class AddLotteriesToSharedUser < ActiveRecord::Migration[7.0]
  def change
    add_column :shared_users, :lotteries, :integer, array: true, default: []
  end
end
