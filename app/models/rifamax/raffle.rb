# == Schema Information
#
# Table name: rifamax_raffles
#
#  id                     :bigint           not null, primary key
#  admin_status           :integer
#  buy_amount             :float
#  buy_currency           :string
#  currency               :string
#  details                :text
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
  
  attr_accessor :need_buy
  attr_accessor :skip_status 
  attr_accessor :cda_sell_type
  attr_accessor :subdomain
  attr_accessor :tokenspj
  attr_accessor :payload
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

  LOTERIES = ['Zulia 7A', 'Zulia 7B', 'Triple Pelotica', 'Triple Rifamax Zodiacal'].freeze 

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

  validates :buy_amount,
            presence: true,
            numericality: {
              greater_than: 0
            },
            if: -> { need_buy }

  validates :buy_currency,
            presence: true,
            inclusion: { in: CURRENCIES },
            if: -> { need_buy }

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

  def handle_cda_payment
    validate_sell_type!
    validate_spj_token!
    validate_raffle_status!
    validate_payload!
    validate_subdomain_presence!
  
    process_payment_action
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

  def sell_some_tickets(tickets_ids = [])
    raise StandardError.new "You are not the seller! This incident will be reported to admins." unless self.seller_id == self.user_who_requested  
    raise StandardError.new "Tickets has been sold!" if self.sell_status == 'sold'
    raise StandardError.new "Ticket list is empty" if tickets_ids.empty?

    tickets = self.tickets.where(id: tickets_ids)
    
    tickets.update_all(
      is_sold: true
    )

    if self.tickets.where(is_sold: false).count == 0
      self.update(
        sell_status: 2
      )
    end

    return { message: "Ticket has been sold!", tickets: ActiveModelSerializers::SerializableResource.new(tickets).as_json }
  end

  private

  PAYMENT_ACTIONS = %w[pay confirm].freeze
  MISSING_SPJ_TOKEN = "Can't perform this action without a SPJ token".freeze
  RAFFLE_NOT_PENDING = 'This raffle is not pending'.freeze
  MISSING_PAYLOAD = 'Payload must be present in the request body'.freeze
  INVALID_SELL_TYPE = 'Invalid sell type'.freeze
  MISSING_SUBDOMAIN = 'Subdomain must be included to perform this action'.freeze

  def pay_triple_body(payload = {}, tokenspj)
    @result = HTTParty.post(
      "#{ENV['cda_url_base']}/centinela/api/v1/ventas/nueva_venta_v2",
      :body => payload.to_json,
      :headers => {
        'Content-Type' => 'application/json',
        'TokenSpj' => tokenspj.to_s
      }
    )

    return unless @result.code == 200
      raise StandardError, "Something failed in payment of triple"
    else
      @result.body
    end
  end

  def confirm_triple_body(payload = {}, tokenspj, subdomain)
    @result = HTTParty.post(
      "#{ENV['cda_url_base']}/centinela/api/v1/ventas/confirmar_venta",
      :body => payload.to_json,
      :headers => {
        'Content-Type' => 'application/json',
        'subdomain' => subdomain.to_s,
        'Tokenspj' => tokenspj.to_s
      }
    )

    return unless @result.code == 200
      raise StandardError, "Something failed in confirmation of triple"
    else
      @result.body
    end
  end

  def validate_sell_type!
    return if PAYMENT_ACTIONS.include?(cda_sell_type)

    raise ArgumentError, INVALID_SELL_TYPE
  end

  def validate_spj_token!
    return if tokenspj.present?

    raise ArgumentError, MISSING_SPJ_TOKEN
  end

  def validate_raffle_status!
    return if admin_status == 'pending'

    raise ArgumentError, RAFFLE_NOT_PENDING
  end

  def validate_payload!
    return if payload.present?

    raise ArgumentError, MISSING_PAYLOAD
  end

  def validate_subdomain_presence!
    return unless cda_sell_type == 'confirm'
    return if subdomain.present?

    raise ArgumentError, MISSING_SUBDOMAIN
  end

  def process_payment_action
    case cda_sell_type
    when 'pay'      then pay_triple_body(payload, tokenspj)
    when 'confirm'  then confirm_triple_body(payload, tokenspj, subdomain)
    end
  end

  def self.statues_by_endpoint(endpoint)
    case endpoint
    when 'newest'
      { sell_status: 0, admin_status: 0 }
    when 'initialized'
      { sell_status: [1, 2], admin_status: [0, 1] }
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
    when 'Tripler Rifamax Zodiacal'
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
