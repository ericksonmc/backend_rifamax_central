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
class Social::ContextSerializer < ActiveModel::Serializer
  attributes :id, :key, :context
end
