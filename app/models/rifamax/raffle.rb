# == Schema Information
#
# Table name: rifamax_raffles
#
#  id                     :bigint           not null, primary key
#  admin_status           :integer
#  currency               :string
#  expired_date           :date
#  init_date              :date
#  lotery                 :string
#  numbers                :integer
#  payment_info           :jsonb
#  price                  :float
#  prizes                 :jsonb            is an Array
#  security               :jsonb
#  sell_status            :integer
#  title                  :string
#  uniq_identifier_serial :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  seller_id              :bigint           not null
#  user_id                :bigint           not null
#
# Indexes
#
#  index_rifamax_raffles_on_seller_id  (seller_id)
#  index_rifamax_raffles_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (seller_id => shared_users.id)
#  fk_rails_...  (user_id => shared_users.id)
#
class Rifamax::Raffle < ApplicationRecord
  # Enums
  enum sell_status: { available: 0, sent: 1, sold: 2 }
  enum admin_status: { pending: 0, payed: 1, unpayed: 2, refunded: 3 }
  
  attr_accessor :skip_status 
  attr_accessor :user_who_requested 

  # Triggers and Callbacks
  before_create :initiliaze_statues, :unless => :skip_status
  before_create :generate_uniq_identifier_serial
  after_create :generate_tickets

  # Associations
  belongs_to :user, class_name: 'Shared::User', foreign_key: 'user_id'
  belongs_to :seller, class_name: 'Shared::User', foreign_key: 'seller_id'

  has_many :tickets, class_name: 'Rifamax::Ticket', foreign_key: 'raffle_id', dependent: :destroy

  # Scopes
  scope :expired, -> { where('expired_date < ?', Date.today) }
  scope :active, -> { where('init_date <= ? AND expired_date >= ?', Date.today, Date.today) }

  # Important variables
  CURRENCIES = %w[USD VES COP].freeze

  LOTERIES = ['Zulia 7A', 'Zulia 7B', 'Triple Pelotica'].freeze 

  ZODIAC = %w[
    Aries
    Tauro
    Geminis
    Cancer
    Leo
    Virgo
    Libra
    Escorpio
    Sagitario
    Capricornio
    Acuario
    Piscis
  ].freeze

  WILDCARDS = [
    'Baloncesto',
    'Beisbol',
    'Futbol',
    'Voleibol',
    'Playa',
    'Golf',
    'Futbol Américano',
    'Tenis',
    'Billar',
    'Bowling',
    'Ping Pong',
    'Hockey'
  ].freeze

  # Validations
  validates :title,
            presence: true,
            length: { minimum: 3, maximum: 35 }
    
  validates :currency,
            presence: true,
            inclusion: { in: CURRENCIES }

  validates :lotery,
            presence: true,
            inclusion: { in: LOTERIES }

  validates :init_date,
            presence: true,
            comparison: { greater_than: Date.yesterday },
            on: :create
            
  validates :numbers,
            presence: true,
            numericality: { 
              only_integer: true, 
              greater_than: 0, 
              less_than: 1000 
            }
          
  validates :price,
            presence: true,
            numericality: {
              greater_than: 0
            }

  # validate :validates_user
  # validate :validates_seller
  validate :validates_prizes
  validate :validates_payment_info

  def self.filter_by_status(user_id, endpoint = 'newest')
    begin
      user = Shared::User.find_by(id: user_id, role: %w[Taquilla Rifero Admin])
      raise StandardError, "Can't perform this action" unless user
      
      case user.role
      when 'Taquilla'
        Rifamax::Raffle.where(user_id: user.id).where(statues_by_endpoint(endpoint))
      when 'Rifero'
        Rifamax::Raffle.where(seller_id: user.id).where(statues_by_endpoint(endpoint))
      when 'Admin'
        Rifamax::Raffle.where(statues_by_endpoint(endpoint))
      else
        { error: "You are not allowed to perform this action" }
      end
    rescue StandardError => e
      { error: e.message }
    end
  end

  def self.need_to_close(user_id, endpoint = 'newest')
    begin
      user = Shared::User.find_by(id: user_id, role: %w[Taquilla Admin])
      raise StandardError, "Can't perform this action" unless user

      case user.role
      when 'Taquilla'
        Rifamax::Raffle.where('expired_date < ?', Date.today, user_id: user.id)
      when 'Admin'
        Rifamax::Raffle.where('expired_date < ?', Date.today, admin_status: 'pending')
      else
        { error: "You are not allowed to perform this action" }
      end 
    rescue StandardError => e
      { error: e.message }
    end
  end

  def self.stats(raffles)
    total_amounts = { usd: 0, ves: 0, cop: 0 }

    raffles.each do |item|
      unless item.payment_info.nil?
        total_amounts[:usd] += item.payment_info['currency'] == 'USD' ? item.payment_info['price'].to_f : 0
        total_amounts[:ves] += item.payment_info['currency'] == 'VES' ? item.payment_info['price'].to_f : 0
        total_amounts[:cop] += item.payment_info['currency'] == 'COP' ? item.payment_info['price'].to_f : 0
      end
    end
    
    return total_amounts
  end

  def sell_all_tickets
    raise StandardError.new "You are not the seller! This incident will be reported to admins." unless self.seller_id == self.user_who_requested  
    raise StandardError.new "Tickets has been sold!" if self.sell_status == 'sold'

    self.update(
      sell_status: 2
    )

    self.tickets.update_all(
      is_sold: true
    )  

    return { message: "Ticket has been sold!", tickets: Rifamax::TicketSerializer.new(self.tickets).object }
  end

  # Shared::User.where(role: 'Taquilla').select { |taquilla| taquilla.rifero_ids.include?(@current_user.id) }.last.id

  private

  def self.statues_by_endpoint(endpoint)
    case endpoint
    when 'newest'
      { sell_status: 0, admin_status: 0 }
    when 'initialized'
      { sell_status: [1, 2], admin_status: 0 }
    when 'to_close'
      { sell_status: [1, 2], admin_status: 0 }
    else
      { sell_status: 0, admin_status: 0 }
    end
  end
  
  def set_security(wildcards)
    position = rand(1..12)

    self.security = {
      position: position,
      wildcard: wildcards[position - 1]
    }
    self.save
  end

  def generate_tickets
    case lotery
    when 'Zulia 7A'
      generate_tickets_for_category(ZODIAC)
      set_security(ZODIAC)
    when 'Zulia 7B'
      generate_tickets_for_category(ZODIAC)
      set_security(ZODIAC)
    when 'Triple Pelotica'
      generate_tickets_for_category(WILDCARDS)
      set_security(WILDCARDS)
    else
      errors.add(:lotery, 'Lotery is not valid')
    end
  end

  def initiliaze_statues
    self.sell_status = 0
    self.admin_status = 0
  end

  def generate_tickets_for_category(category)
    if tickets.any?
      errors.add(:tickets, 'Tickets already exists')
      return
    end
    ActiveRecord::Base.transaction do
      category.each_with_index do |item, index|
        Rifamax::Ticket.create(
          wildcard: item,
          number: numbers,
          number_position: index + 1,
          is_sold: false,
          raffle_id: id
        )
      end
    end
  end

  def generate_uniq_identifier_serial
    self.uniq_identifier_serial = SecureRandom.uuid
  end

  # Validations

  # def validates_user
  #   errors.add(:user_id, 'You are not allowed to perform this action') unless shared_user.role == 'Taquilla'
  # end

  # def validates_seller
  #   errors.add(:seller_id, 'You are not allowed to perform this action') unless seller.role == 'Rifero'
  #   errors.add(:seller_id, 'Must be belongs to user') unless user.rifero_ids.include?(seller.id)
  # end

  def validates_prizes
    errors.add(:prizes, 'Prizes must be an array') unless prizes.is_a?(Array)

    prizes.each do |prize|
      errors.add(:prizes, 'Prize must be a hash') unless prize.is_a?(Hash)
      errors.add(:prizes, 'Prize must have award key') unless prize.key?('award')
      errors.add(:prizes, 'Prize must have plate key') unless prize.key?('plate')
      errors.add(:prizes, 'Prize must have is_money key') unless prize.key?('is_money')
      errors.add(:prizes, 'Prize must have wildcard key') unless prize.key?('wildcard')
    end
  end

  def validates_payment_info
    allowed_currencies = ['USD', 'VES', 'COP']
    
    errors.add(:payment_info, 'Payment info must be nil or hash') unless payment_info.nil? || payment_info.is_a?(Hash)

    if payment_info.is_a?(Hash) 
      errors.add(:payment_info, 'Payment info must have price key') unless payment_info.key?('price')
      
      if payment_info['price'].is_a?(Numeric)
        errors.add(:payment_info, 'Payment info must have price key') unless payment_info['price'] >= 1
      end

      errors.add(:payment_info, 'Payment info must have currency key') unless payment_info.key?('currency')
      
      if payment_info.key?('currency')
        errors.add(:payment_info, 'Currency key must be `USD`, `VES`, `COP`') unless allowed_currencies.include?(payment_info['currency'])
      end
    end
  end
end
