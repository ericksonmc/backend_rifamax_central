class Shared::StructureSerializer < ActiveModel::Serializer
  attributes :id, :name, :known_as
end
