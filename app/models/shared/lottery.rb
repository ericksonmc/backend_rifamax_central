# == Schema Information
#
# Table name: shared_lotteries
#
#  id         :bigint           not null, primary key
#  name       :string
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Shared::Lottery < ApplicationRecord
end
