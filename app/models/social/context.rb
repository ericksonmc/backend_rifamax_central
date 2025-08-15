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
end
