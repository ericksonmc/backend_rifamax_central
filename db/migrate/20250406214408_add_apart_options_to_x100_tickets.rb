class AddApartOptionsToX100Tickets < ActiveRecord::Migration[7.0]
  def change
    add_column :x100_tickets, :apart_ends, :datetime
    add_column :x100_tickets, :aparted_by, :integer
  end
end
