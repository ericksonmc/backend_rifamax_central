class Shared::SpriteSerializer < ActiveModel::Serializer
  attributes :asset, 
             :each_height, 
             :each_width, 
             :each_dimensions, 
             :height, 
             :width, 
             :image_dimensions, 
             :identifier

  def asset 
    ENV['url_base'] + object.asset&.url
  end

  def each_dimensions
    "#{each_width}x#{each_height}"
  end

  def image_dimensions
    "#{width}x#{height}"
  end
end
