# frozen_string_literal: true

# == Schema Information
#
# Table name: shared_users
#
#  id              :bigint           not null, primary key
#  avatar          :string
#  dni             :string
#  email           :string
#  integrator_type :string
#  is_active       :boolean
#  is_first_entry  :boolean          default(FALSE)
#  is_integration  :boolean          default(FALSE)
#  lotteries       :integer          default([]), is an Array
#  module_assigned :integer          default([]), is an Array
#  name            :string
#  password_digest :string
#  phone           :string
#  rifero_ids      :integer          default([]), is an Array
#  role            :string
#  slug            :string
#  welcoming       :boolean          default(TRUE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  integrator_id   :integer
#  structure_id    :integer
#
module Shared
  class UserSerializer < ActiveModel::Serializer
    attributes :id, :integrator_id, :avatar, :name, :integrator_type, :email, :dni, :is_active, :phone, :influencer_id, :content_code, :role, :structure, :is_first_entry, :welcoming, :show_badge, :social_payment_options

    def influencer_id
      object.social_influencer&.id
    end

    def avatar
      return nil if object.avatar.url.nil?

      ENV['url_base'] + object.avatar&.url
    end

    def content_code
      object.social_influencer&.content_code
    end

    def show_badge
      object.social_influencer&.show_badge
    end

    def structure
      object&.structure_id === nil ? nil : Shared::Structure.find(object&.structure_id)
    end

    def social_payment_options
      object.social_influencer&.payment_options || []
    end

    # def riferos
    #   Shared::User.where(id: object.rifero_ids)
    #               .select(:id, :dni, :email, :is_active, :phone)
    #               .map do |user|
    #     {
    #       id: user.id,
    #       dni: user.dni,
    #       email: user.email,
    #       is_active: user.is_active,
    #       role: 'Rifero',
    #       phone: user.phone
    #     }
    #   end
    # end
  end
end
