# == Schema Information
#
# Table name: social_payment_methods
#
#  id                   :bigint           not null, primary key
#  amount               :float
#  currency             :string
#  details              :jsonb
#  email_send           :boolean          default(FALSE)
#  payment              :string
#  payment_rate         :float
#  quantity_requested   :integer
#  status               :string
#  whatsapp_send        :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  shared_exchange_id   :bigint
#  social_client_id     :bigint           not null
#  social_influencer_id :bigint
#  social_raffle_id     :bigint
#
# Indexes
#
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
  before_validation :initialize_currency
  before_validation :initialize_exchange
  before_save :initialize_status
  before_create :notify_payment
  # before_create :calculate_amount

  # ------ Belongs to association
  belongs_to :social_client, class_name: 'Social::Client', foreign_key: 'social_client_id'
  belongs_to :social_influencer, class_name: 'Social::Influencer', foreign_key: 'social_influencer_id', optional: true
  belongs_to :social_raffle, class_name: 'Social::Raffle', foreign_key: 'social_raffle_id', optional: true

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
    if status == 'active'
      update(status: "accepted")
      # Social::PaymentMailer.order_email(
      #   social_client,
      #   social_raffle,
      #   amount,
      #   currency,
      #   [*1..10000].sample(quantity_requested).uniq
      # ).deliver_now
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

  def send_order_email
    Social::PaymentMailer.order_email(
      social_client,
      social_raffle,
      amount,
      currency,
      [*1..10000].sample(quantity_requested).uniq
    ).deliver_now
  end

  def consult_body
    return unless status == 'active' && payment == 'Pago Movil'

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


  private

  def notify_payment
    return true unless status == 'active' && payment == 'Pago Movil'

    monto = amount.to_s
    referencia = details["reference"].to_s
    telefono_emisor = "0#{details["phone"].gsub(/\D/, "")}",
    codigo_red = '00'
    banco_emisor = BanksService.new.find_bank(details["bank"])[:code].slice(1, 4)
    fecha_hora = Date.parse(details["payment_date"]).strftime('%Y-%m-%d')
    concepto = ''

    raise "Bank code not found" if banco_emisor.nil? || banco_emisor.empty?

    r4_result = $redis.get("R4:#{telefono_emisor}:#{referencia}:#{banco_emisor}:#{fecha_hora}")

    final_result = if r4_result.nil?
      false
    elsif  r4_result.to_f == monto.to_f
      self.status = "accepted"
      self.save
      true
    else
      false
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
    self.status = "active"
  end

  def initialize_exchange
    self.payment_rate = Social::R4ConectaService.new.consultar_tasa_bcv["tipocambio"].to_f

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
