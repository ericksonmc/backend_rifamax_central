# == Schema Information
#
# Table name: social_lotteries
#
#  id         :bigint           not null, primary key
#  key_name   :string
#  name       :string
#  profit_fee :float
#  status     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Social::Lottery < ApplicationRecord
   has_many :social_raffles, class_name: 'Social::Raffle', foreign_key: 'social_lottery_id', dependent: :destroy

  # ----- Validations
  validates :name,
            presence: true,
            uniqueness: true

  validates :profit_fee,
            numericality: {
              less_than_or_equal_to: 100,
              greater_than_or_equal_to: 0
            }

  validates :key_name,
            presence: true,
            uniqueness: true

  validates :status,
            presence: true,
            inclusion: { in: %w[active inactive] }

  # ----- Callbacks
  before_validation :initialize_status

  # ----- Instance methods
  def inactive?
    status == 'inactive'
  end

  def active?
    status == 'active'
  end

  def self.active
    where(status: 'active')
  end

  def self.inactive
    where(status: 'inactive')
  end

  def inactive!
    update(status: 'inactive')
  end

  def active!
    update(status: 'active')
  end

  def toggle_status!
    if active?
      inactive!
    else
      active!
    end
  end

  def self.available_lotteries
    lotteries = Social::Lottery.all
    result = []

    lotteries.each do |lottery|
      if lottery.status == 'active'
        result << {
          value: lottery.id,
          label: lottery.name,
          profit_fee: lottery.profit_fee,
        }
      end
    end

    result
  end

  # ----- Private methods
  private

  def initialize_status
    self.status = 'active' if status.nil?
  end
end
