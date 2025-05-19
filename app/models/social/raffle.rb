# == Schema Information
#
# Table name: social_raffles
#
#  id                   :bigint           not null, primary key
#  ad                   :string
#  combos               :jsonb
#  draw_type            :string
#  expired_date         :datetime
#  has_winners          :boolean
#  init_date            :datetime
#  limit                :integer
#  money                :string
#  price_unit           :float
#  prizes               :jsonb
#  raffle_type          :string
#  status               :string
#  tickets_count        :integer
#  title                :string
#  winners              :jsonb
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  social_influencer_id :bigint           not null
#
# Indexes
#
#  index_social_raffles_on_social_influencer_id  (social_influencer_id)
#
# Foreign Keys
#
#  fk_rails_...  (social_influencer_id => social_influencers.id)
#
class Social::Raffle < ApplicationRecord
  self.table_name = 'social_raffles'

  # ------ Scope by status
  scope :active, -> { where(status: 'En venta' )}
  scope :closing, -> { where(status: 'Finalizando' )}
  scope :closed, -> { where(status: 'Cerrado' )}

  # ------ Scope by category
  scope :infinite, -> { where(raffle_type: 'Infinito', status: 'En venta')}
  scope :triple, -> { where(raffle_type: 'Triple', status: 'En venta')}
  scope :terminal, -> { where(raffle_type: 'Terminal', status: 'En venta')}

  # ------ Foreign Keys Beloging
  belongs_to :social_influencer, class_name: 'Social::Influencer', foreign_key: 'social_influencer_id'
  
  # ------ Associations/relationships between tables
  has_many :social_tickets, class_name: 'Social::Ticket', foreign_key: 'social_raffle_id', dependent: :destroy
  has_many :social_orders, class_name: 'Social::Order', foreign_key: 'social_raffle_id'
  has_many :social_orders, class_name: 'Social::Order', foreign_key: 'social_raffle_id'
  has_many :social_payment_methods, class_name: 'Social::PaymentMethod', foreign_key: 'social_raffle_id'

  # ------ Utils and tools
  mount_uploader :ad, Social::AdUploader
  
  # ------ Triggers or before/after actions
  before_validation :initialize_attributes
  after_create :generate_tickets

  # ------ Validations
  validates :status,
            presence: true,
            inclusion: { in: ['En venta', 'Finalizando', 'Cerrado'] }

  validates :draw_type,
            presence: true,
            inclusion: { in: %w[Progresiva Limitada] }

  validates :raffle_type,
            inclusion: { in: %w[Serie Infinito Terminal Triple] }

  validates :limit,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 100
            },
            if: -> { draw_type == 'Progresiva' }

  validates :tickets_count,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 100,
              less_than_or_equal_to: 1000
            },
            if: -> { raffle_type != 'Infinito' }

  validates :money,
            inclusion: { in: %w[VES USD COP] }

  validates :init_date,
            presence: {
              message: 'Could be provide an init date param'
            },
            comparison: {
              greater_than_or_equal_to: Date.current 
            },
            if: -> { new_record? || will_save_change_to_init_date? }
              
  validates :expired_date,
            presence: {
              message: 'Could be provide an expired date param'
            },
            comparison: {
              greater_than_or_equal_to: :init_date
            },
            if: -> { draw_type == 'Limitada'}

  validates :social_influencer_id,
            presence: true
  
  validate :validates_influencer
  
  # ------ Public logic of model
  def winners
    return nil if self.has_winners.nil?
    return self.has_winners if self.has_winners.is_a?(Array)
    return self.has_winners
  end

  def self.details(action_perfomed = 'picture')
    actions = {
      "picture": "social_raffles_details_pictures",
      "winners": "social_raffles_details_winners"
    }

    smembers = $redis.smembers(actions[action_perfomed.to_sym])

    message = smembers.empty? ? 'No actions needed!' : 'Action needed!'

    return { data: smembers.map { |json_str| JSON.parse(json_str) }, action: action_perfomed, message: message }
  end

  def add_to_pending(action)
    return $redis.sadd("social_raffles_details_#{action}", self.slice(:id, :title, :price_unit, :status, :init_date, :social_influencer_id).to_json) == 1
  end

  def stats
    result = self.class.connection.execute(
      ActiveRecord::Base.send(
        :sanitize_sql_array, 
        [<<-SQL, self.id]
          SELECT 
            SUM(
              CASE 
                WHEN spm.status = 'accepted' THEN 
                  CASE 
                    WHEN spm.currency = 'VES' THEN spm.amount / se.value_bs
                    WHEN spm.currency = 'COP' THEN spm.amount / se.value_cop
                    ELSE spm.amount
                  END
                ELSE 0
              END
            ) AS total_profit, 
            COUNT(CASE WHEN spm.status = 'accepted' THEN 1 END) AS quantity_sold,
            COUNT(CASE WHEN spm.status = 'rejected' THEN 1 END) AS rejected_payments,
            COUNT(CASE WHEN spm.status = 'active' THEN 1 END) AS unverified_payments
          FROM social_payment_methods spm
          INNER JOIN shared_exchanges se ON se.id = spm.shared_exchange_id
          WHERE spm.social_raffle_id = ?
        SQL
      )
    ).first
  
    rejected_payments = result['rejected_payments'].to_i
    unverified_payments = result['unverified_payments'].to_i
    total_profit = result['total_profit'].to_f.round(2)
    quantity_sold = result['quantity_sold'].to_i
  
    {
      rejected_payments: rejected_payments,
      unverified_payments: unverified_payments,
      total_profit: total_profit,
      quantity_sold: quantity_sold
    }
  end
  
  # ------ Private logic of model
  private

  def initialize_attributes
    self.status = 'En venta'
    self.money = 'USD'
    self.raffle_type = case tickets_count
                       when 100
                         'Terminal'
                       when 1000
                         'Triple'
                       when 10000
                         'Serie'
                       else
                         'Infinito'
                       end
  end

  def generate_tickets
    raffle_type_unaccepted = ['Infinito', 'Serie']
    
    unless self.raffle_type.includes?(raffle_type_unaccepted)
      tickets = []

      tickets_count.times do |position|
        tickets << {
          position: position + 1,
          price: nil,
          money: nil,
          x100_raffle_id: id,
          x100_client_id: nil,
          serial: SecureRandom.uuid
        }
      end

      X100::Ticket.insert_all(tickets)
    end
  end
  
  def initialize_ticket
    $redis.set("social_sold_serie:#{self.id}", [])
  end

  def validates_influencer
    return unless Social::Influencer.find(social_influencer_id).shared_user.role != 'Influencer'

    errors.add(:social_influencer_id, 'Influencer must exists')
  end
end
