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
class Shared::ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :image, :color, :to, :roles, :devices

  def image
    ENV['url_base'] + object.image&.url
  end
end
