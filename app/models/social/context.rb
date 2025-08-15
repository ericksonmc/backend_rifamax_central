# == Schema Information
#
# Table name: social_contexts
#
#  id         :bigint           not null, primary key
#  context    :jsonb
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Social::Context < ApplicationRecord

  # Validations
  validates :key, presence: true, uniqueness: true
  validates :context, presence: true, json: true

  # Scopes
  scope :by_key, ->(key) { where(key: key) }

  # Class methods
  def self.find_by_key(key)
    by_key(key).first
  end

  # Instance methods
  def to_s
    "#{key}: #{context}"
  end

  # Additional methods can be added here as needed
  def self.create_or_update_context(key, context_data)
    context = find_by_key(key)
    if context
      context.update(context: context_data)
    else
      create(key: key, context: context_data)
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create or update social context: #{e.message}")
    nil
  end

  private 

  def initialize_context
    if new_record?
      self.context = {
        last_agent_response: nil,               # -> Last response from AI
        last_user_message: nil,                 # -> Last message from the user
        raffle_id: nil,                         # -> ID of the raffle
        client_id: nil,                         # -> ID of the client
        tickets_quantity: 0,                    # -> Tickets quantity
        payment_method_selected: nil,           # -> Payment methods between (Pago Movil or Zelle)
        fractions: nil,                         # -> Default by 1 (only on pago movil)
        current_user_step: 'VERIFY_RAFFLE',     # -> Current step of the user in the process
        payment_method_data: {                  # -> Payment data accord to payment methods with
          name: nil,                            # -> Name of the holder of the payment method *(only on zelle)
          email: nil,                           # -> email of the holder of the payment method *(only on zelle)
          bank: nil,                            # -> a bank name in the list of available banks (only on pago movil)
          phone: nil,                           # -> +58 (412) 000-0000 (only on pago movil)
          payment_date: nil,                    # -> YYYY-mm-dd (only on pago movil)
          reference: nil                        # -> 9-12 digits (only on pago movil)
        }
      }
    end    
end
