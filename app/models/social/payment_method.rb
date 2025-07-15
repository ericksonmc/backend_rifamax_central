# == Schema Information
#
# Table name: social_payment_methods
#
#  id                   :bigint           not null, primary key
#  amount               :float
#  currency             :string
#  details              :jsonb
#  email_send           :boolean          default(FALSE)
#  fly_amounts          :float            default([]), is an Array
#  fraction_debt        :float
#  fractions            :integer          default(1)
#  has_fly_amount       :boolean          default(FALSE)
#  is_fractionated      :boolean          default(FALSE)
#  payment              :string
#  payment_rate         :float
#  quantity_requested   :integer
#  serial               :string
#  status               :string
#  tickets              :integer          default([]), is an Array
#  whatsapp_send        :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  fraction_id          :bigint
#  shared_exchange_id   :bigint
#  social_client_id     :bigint           not null
#  social_influencer_id :bigint
#  social_raffle_id     :bigint
#
# Indexes
#
#  index_social_payment_methods_on_serial                (serial) UNIQUE
#  index_social_payment_methods_on_shared_exchange_id    (shared_exchange_id)
#  index_social_payment_methods_on_social_client_id      (social_client_id)
#  index_social_payment_methods_on_social_influencer_id  (social_influencer_id)
#  index_social_payment_methods_on_social_raffle_id      (social_raffle_id)
#
# Foreign Keys
#
#  fk_rails_...  (shared_exchange_id => shared_exchanges.id)
#  fk_rails_...  (social_client_id => social_clients.id)
#  fk_rails_...  (social_influencer_id => social_influencers.id)
#  fk_rails_...  (social_raffle_id => social_raffles.id)
#
class Social::PaymentMethod < ApplicationRecord
  # ------ Triggers
  before_validation :generate_serial
  before_validation :initialize_status
  before_validation :initialize_currency
  before_validation :initialize_exchange
  before_create :notify_payment
  # before_create :calculate_amount

  # ------ Belongs to association
  belongs_to :social_client, class_name: 'Social::Client', foreign_key: 'social_client_id'
  belongs_to :social_raffle, class_name: 'Social::Raffle', foreign_key: 'social_raffle_id', optional: true
  belongs_to :social_influencer, class_name: 'Social::Influencer', foreign_key: 'social_influencer_id', optional: true

  # ------ Associations/relationships between tables
  # has_many :social_orders, class_name: 'Social::Order', foreign_key: 'social_payment_method_id', dependent: :destroy

  # ------ Attribute acessors

  # ------ Validations
  validates :payment, 
            presence: true, 
            inclusion: { in: ["Stripe", "Pago Movil", "Zelle", "Paypal"] }

  validates :details, presence: true

  validates :amount, 
            presence: true,
            numericality: { greater_than: 0 }

  validates :status,
            presence: true,
            inclusion: { in: ["active", "accepted", "rejected", "refunded"] }

  validates :serial,
            presence: true

  validates :social_influencer_id, presence: true

  validates :social_raffle_id, presence: true

  validate :validates_details
  
  # validate :validates_repeat_payments
  
  # ------ Methods

  def self.authorize(user_id)
    user = Shared::User.find_by(id: user_id)
    raise "Invalid user data type" if user.nil?
  
    case user.role
    when "Admin"
      self.all
    when "Influencer"
      self.where(social_influencer_id: user.social_influencer.id)
    else
      raise "You don't have permission to perform this action."
    end
  end

  def self.authorize_with_payment(user_id, payment)
    user = Shared::User.find_by(id: user_id)
    raise "Invalid user data type" if user.nil?
    raise "Invalid payment data type" unless payment.is_a?(String)

    payments_accepted =  ["Stripe", "Pago Movil", "Zelle", "Paypal"]

    raise "Invalid payment method" unless payments_accepted.include?(payment)
  
    case user.role
    when "Admin"
      self.where.not("status = ?", "active").where(payment: payment)
    when "Influencer"
      self.where.not("status = ?", "active").where(social_influencer_id: user.social_influencer.id, payment: payment)
    else
      raise "You don't have permission to perform this action."
    end
  end

  def self.active
    where(status: "active")
  end

  def self.accepted
    where(status: "accepted")
  end

  def self.rejected
    where(status: "rejected")
  end

  def self.refunded
    where(status: "refunded")
  end

  def active?
    status == "active"
  end

  def accepted?
    status == "accepted"
  end

  def rejected?
    status == "rejected"
  end

  def accept!
    return false unless status == 'active'
    if update(status: "accepted")
      true
    else
      errors.add(:base, "Failed to update status: #{errors.full_messages.join(', ')}")
      false
    end
  rescue StandardError => e
    errors.add(:base, "Failed to send email: #{e.message}")
    false
  end

  def reject!
    if status == 'active'
      update(status: "rejected")
    end
  end

  def refund!
    update(status: "refunded")
  end

  def send_preorder_email
    unless self.email_send
      Social::PaymentMailer.pre_order_email(
        self.social_client,
        self.social_raffle,
        self.amount,
        self.currency
      ).deliver_now
      self.email_send = true
      self.save
    else
      raise StandardError.new("Email was send!")
    end
  end

  def send_order_email(email)
    Social::PaymentMailer.order_email(
      email,
      self.social_raffle,
      self.currency == 'USD' ? self.amount : self.amount * self.payment_rate,
      self.currency,
      self.tickets
    ).deliver_now
    self.email_send = true
    self.save
  end
tables 
  def consult_body
    return unless  payment == 'Pago Movil'

    monto = amount.to_s
    referencia = details["reference"].to_s
    telefono_emisor = "0#{details["phone"].gsub(/\D/, "")}",
    codigo_red = '00'
    banco_emisor = BanksService.new.find_bank(details["bank"])[:code].slice(1, 4)
    fecha_hora = Date.parse(details["payment_date"]).strftime('%Y-%m-%d')
    concepto = ''

    @consult_body = {
      telefono_emisor: telefono_emisor,
      monto: monto,
      referencia: referencia,
      codigo_red: codigo_red,
      banco_emisor: banco_emisor,
      fecha_hora: fecha_hora,
      concepto: concepto,
    }
  end

  def pay_fraction_in_ves(payment_details)
    return unless is_fractionated
    return unless payment == 'Pago Movil'

    if fraction_debt <= 0.0
      errors.add(:base, "No debt to pay")
      throw(:abort)
    end

    amount_to_pay = (amount / fractions).round(2)

    origin_reference = payment_details["reference"].to_s
    length = origin_reference.length < 9 ? -origin_reference.length : -9

    referencia = origin_reference[length..]
    banco_emisor = BanksService.new.find_bank(payment_details["bank"])[:code].slice(1, 4)
    fecha_hora = Date.parse(payment_details["payment_date"]).strftime('%Y-%m-%d')
    monto = (amount_to_pay.to_f * Social::R4ConectaService.new.consultar_tasa_bcv(fechavalor: fecha_hora)["tipocambio"].to_f).to_s

    raise "Bank code not found" if banco_emisor.nil? || banco_emisor.empty?

    redis_param = "R4:#{telefono_emisor}:#{referencia}:#{banco_emisor}:#{fecha_hora}"

    r4_result = $redis.get(redis_param)

    final_result = if r4_result.nil?
      false
    else
      if (monto.to_f - r4_result.to_f).abs <= 2
        $redis.del(redis_param)
        self.fraction_debt = fraction_debt - amount_to_pay
        self.fly_amounts ||= []
        self.fly_amounts << (monto.to_f).round(2)
        true
      else 
        errors.add(:base, "Monto errado - Monto esperado #{(monto.to_f / self.fractions).round(2)}, Monto obtenido #{r4_result}")
        false
      end
    end

    unless final_result
      errors.add(:base, "Failed to notify payment")
      throw(:abort)
    end
  end

  private

  def notify_payment
    return true unless payment == 'Pago Movil'

    origin_references = details["reference"].to_s

    length = origin_references.length < 9 ? -origin_references.length : -9

    referencia = origin_references[length..]
    telefono_emisor = "0#{details["phone"].gsub(/\D/, "")}"
    banco_emisor = BanksService.new.find_bank(details["bank"])[:code].slice(1, 4)
    fecha_hora = Date.parse(details["payment_date"]).strftime('%Y-%m-%d')
    monto = (amount.to_f * Social::R4ConectaService.new.consultar_tasa_bcv(fechavalor: fecha_hora)["tipocambio"].to_f).to_s

    raise "Bank code not found" if banco_emisor.nil? || banco_emisor.empty?

    redis_param = "R4:#{telefono_emisor}:#{referencia}:#{banco_emisor}:#{fecha_hora}"

    r4_result = $redis.get(redis_param)

    final_result = if r4_result.nil?
      false
    else
      if ((monto.to_f / self.fractions) - r4_result.to_f).abs <= 2
        $redis.del(redis_param)
        self.status = "accepted"
        self.fraction_debt = self.fractions > 1 ? self.amount - (self.amount / self.fractions) : 0.0
        self.fly_amounts ||= []
        self.fly_amounts << (monto.to_f / self.fractions).round(2)
        self.is_fractionated = self.fractions > 1
        self.save
        true
      else
        errors.add(:base, "Monto errado - Monto esperado #{(monto.to_f / self.fractions).round(2)}, Monto obtenido #{r4_result}")
        false
      end
    end

    unless final_result
      errors.add(:base, "Failed to notify payment")
      throw(:abort)
    end
  end

  def calculate_amount
    raffle = Social::Raffle.find(social_raffle_id)
    base_amount = (quantity_requested * raffle.price_unit)

    self.amount =  case currency
    when 'USD'
      base_amount
    when 'VES'
      base_amount * payment_rate
    else
      base_amount
    end.round(2)
  end

  def initialize_status
    if new_record?
      if payment == 'Pago Movil'
        self.status = "accepted"
      else
        self.status = "active"
      end
    end
  end

  def generate_serial
    loop do
      serial = "ORD-#{SecureRandom.random_number(10**11).to_s.rjust(11, '0')}"
      unless Social::PaymentMethod.exists?(serial: serial)
        if new_record?
          self.serial = serial
        end
        break
      end
    end
  end

  def initialize_exchange
    return unless new_record?

    payment_rating = Shared::Exchange.get_bsd
    payment_date = self.details["payment_date"] || Date.current

    if Date.parse(payment_date) < Date.current
      payment_rating = Social::R4ConectaService.new.consultar_tasa_bcv(fechavalor: payment_date)["tipocambio"]
    end
    
    self.payment_rate = payment_rating
  rescue StandardError => e
    Rails.logger.error("Error initializing exchange rate: #{e.message}")
    errors.add(:base, "Failed to initialize exchange rate")
    throw(:abort)
  end

  def initialize_currency
    self.currency = case payment
    when "Stripe"
      "USD"
    when "Pago Movil"
      "VES"
    when "Zelle"
      "USD"
    when "Paypal"
      "USD"
    end
  end
  
  def validates_details
    case payment
    when "Stripe"
      validates_stripe
    when "Pago Movil"
      validates_pago_movil
    when "Zelle"
      validates_zelle
    when "Paypal"
      validates_paypal
    end
  end

  def validates_stripe
    errors.add(:details, "Bank is not present") unless details["bank"].present?
    errors.add(:details, "Name is not present") unless details["name"].present?
    errors.add(:details, "Last four digits is not present") unless details["last_digits"].present?
  end

  def validates_pago_movil
    errors.add(:details, "Bank is not present") unless details["bank"].present?
    errors.add(:details, "Phone is not present") unless details["phone"].present?
    errors.add(:details, "Payment date is not present") unless details["payment_date"].present?
    errors.add(:details, "References is not present") unless details["reference"].present?
  end

  def validates_zelle
    errors.add(:details, "Name is not present") unless details["name"].present?
    errors.add(:details, "Reference is not present") unless details["reference"].present?
  end

  def validates_paypal
    errors.add(:details, "Email is not present") unless details["email"].present?
  end

  def validates_repeats_zelle
    zelle_payments = Social::PaymentMethod
      .where(
        social_client_id: social_client_id,
        payment: payment, 
        status: "active"
      )
      .where("details->>'reference' = ?", details["reference"])
      .count
      .positive?

    errors.add(:details, "Reference already exists") if zelle_payments
  end

  def validates_repeat_payments
    case payment
    when "Zelle"
      validates_repeats_zelle
    else
      nil
    end
  end
end
