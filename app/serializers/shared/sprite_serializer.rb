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
class Shared::SpriteSerializer < ActiveModel::Serializer
  attributes :asset, 
             :each_height, 
             :each_width, 
             :each_dimensions, 
             :height, 
             :width, 
             :quantity,
             :image_dimensions, 
             :identifier

  def asset 
    ENV['url_base'] + object.asset&.url
  end

  def each_dimensions
    "#{object.each_width}x#{object.each_height}"
  end

  def image_dimensions
    "#{object.width}x#{object.height}"
  end

  def quantity
    (object.width / object.each_width).round(0)
  end
end
