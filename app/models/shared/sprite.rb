# == Schema Information
#
# Table name: shared_sprites
#
#  id          :bigint           not null, primary key
#  asset       :string
#  each_height :integer
#  each_width  :integer
#  height      :integer
#  identifier  :string
#  width       :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Shared::Sprite < ApplicationRecord
  mount_uploader :asset, Shared::AssetUploader

  validates :asset,
            presence: true

  validates :each_width,
            presence: true,
            numericality: {
              greater_than: 0
            }

  validates :each_height,
            presence: true,
            numericality: {
              greater_than: 0
            }

  validates :width,
            presence: true,
            numericality: {
              greater_than: 0
            }

  validates :height,
            presence: true,
            numericality: {
              greater_than: 0
            }

  validates :identifier,
            presence: true,
            uniqueness: true

  def self.get_sprite(identifier)
    Shared::Sprite.find_by(identifier: identifier)
  end
end
