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
