# == Schema Information
#
# Table name: shared_products
#
#  id         :bigint           not null, primary key
#  color      :string
#  devices    :string           default([]), is an Array
#  image      :string
#  name       :string
#  roles      :string           default([]), is an Array
#  to         :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Shared::Product < ApplicationRecord
  mount_uploader :image, Shared::ImageUploader

  ROLES = %w[Admin Taquilla Rifero Desarrollador].freeze
  PLATFORM = %w[PC Tablet Android iOS].freeze

  validates :name,
            presence: true

  validates :image,
            presence: true

  validates :color,
            presence: true

  validates :to,
            presence: true
    
  validates :roles,
            presence: true,
            inclusion: { in: ROLES }

  validates :devices,
            presence: true,
            inclusion: { in: PLATFORM }

  def self.has?(attr = '', value = [])
    where("#{attr} && ARRAY[?]::varchar[]", value)
  end

  def self.search_devices(devices = [])
    has?('devices', devices)
  end
  
  def self.allow_modules(role, devices = [])
    search_devices(devices).select{ |product| product.roles.include?(role) }
  end
end
