class AddMinTicketBuyToSocialRaffles < ActiveRecord::Migration[7.0]
  def change
    add_column :social_raffles, :min_ticket_buy, :integer, default: 1
  end
end
