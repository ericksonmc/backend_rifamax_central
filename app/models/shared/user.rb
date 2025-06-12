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
  class User < ApplicationRecord
    has_one :shared_wallet, class_name: 'Shared::Wallet', foreign_key: 'shared_user_id', dependent: :destroy
    has_many :rifamax_raffles, class_name: 'Rifamax::Raffle', foreign_key: 'user_id', dependent: :destroy
    has_many :rifamax_sellers, class_name: 'Rifamax::Raffle', foreign_key: 'seller_id', dependent: :destroy
    has_many :x100_order, class_name: 'X100::Order', foreign_key: 'shared_user_id', dependent: :destroy
    has_one :shared_structure, class_name: 'Shared::Structure', foreign_key: 'shared_user_id', dependent: :destroy
    has_one :social_influencer, class_name: 'Social::Influencer', foreign_key: 'shared_user_id', dependent: :destroy

    mount_uploader :avatar, Shared::AvatarUploader

    has_secure_password

    after_create :generate_wallet
    after_create :generate_slug
    after_create :generate_influencer

    enum :role, {
      Admin: 'admin',
      Agente: 'agente',
      Taquilla: 'taquilla',
      Rifero: 'rifero',
      Loteria: 'loteria',
      Influencer: 'influencer',
      Autotaquilla: 'autotaquilla'
    }

    scope :active, -> { where(is_active: true) }
    scope :inactive, -> { where(is_active: false) }

    EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

    # Validations

    validates :name,
              presence: true

    validates :role,
              presence: true

    validates :dni,
              uniqueness: {
                message: 'Ya existe un cliente con este número de cédula'
              },
              presence: {
                message: 'Debe introducir un número de cédula'
              },
              length: {
                minimum: 8,
                message: 'Debe ser mayor a 8 digitos'
              },
              format: {
                with: /\A[VEJG]-\d{1,10}\z/,
                message: 'Debe incluir (V J E G)'
              },
              if: -> { !Loteria? || (phone.present? && phone.starts_with?('+58')) }

    validates :phone,
              format: {
                with: /\A\+\d{1,4} \(\d{1,4}\) \d{1,10}-\d{1,10}\z/,
                message: 'Introduzca un número de teléfono válido en el formato: +prefijo telefónico (codigo de area) tres primeros dígitos - dígitos restantes, por ejemplo: +58 (416) 000-0000'
              },
              if: -> { (!Loteria? || !is_integration) && phone.present? }

    validates :email,
              presence: true,
              uniqueness: { case_sensitive: false },
              format: { with: EMAIL_REGEX },
              if: -> { !is_integration }

    validates :password,
              length: { minimum: 6 },
              if: -> { new_record? || !password.nil? }

    validate :validate_riferos

    def taquillas
      return "Can't show taquillas, user are not rifero or admin." unless %w[Rifero Admin].include?(role)

      case role
      when 'Rifero'
        Shared::User.where('rifero_ids @> ARRAY[?]', id)
      when 'Admin'
        Shared::User.where(role: 'Taquilla')
      end
    end

    def zodiacal_is_blocked
      raffles = Rifamax::Raffle.filter_by_status(self.id, 'to_close').where('expired_date < ?', Date.today)
    
      if raffles.count > 0
        return { is_blocked: true }
      end

      { is_blocked: false }
    end

    def self.cda_login(email, password)
      url = 'https://www.testcda.com/api/v1/login'
      body = {
        :email => email,
        :password => password
      }.to_json
      headers = { 
        'Content-Type' => 'application/json'
      }

      response = HTTParty.post(
        url,
        :body => body,
        :headers => headers
      )

      return response
    end

    def self.login_integration(username, password, structure_id, structure_type)
      raise StandardError.new("Add username") if username.blank?
      raise StandardError.new("Add password") if password.blank?
      raise StandardError.new("Add structure_id") if structure_id.nil?
      raise StandardError.new("Add structure_type") if structure_type.blank?

      @user = Shared::User.find_by(name: username, integrator_type: structure_type)

      if @user.nil?
        @new_integration = Shared::User.new(
          id: Shared::User.last.id + 1,
          name: username,
          role: 'Taquilla',
          dni: nil,
          email: nil,
          phone: '',
          password: password,
          password_confirmation: password,
          slug: username.parameterize,
          is_active: true,
          rifero_ids: [],
          module_assigned: [2],
          is_integration: true,
          is_first_entry: true,
          welcoming: false,
          structure_id: 1,
          integrator_id: structure_id,
          integrator_type: structure_type,
        )

        if @new_integration.save
          time = 7.days.from_now
          token = JsonWebToken.encode({ user_id: @new_integration.id }, time)

          return { token: token, exp: time.strftime('%m-%d-%Y %H:%M'), user: Shared::UserSerializer.new(@new_integration) }
        else
          raise StandardError.new("Unauthorized")
        end
      else
        if @user&.authenticate(password)
          time = 7.days.from_now
          token = JsonWebToken.encode({ user_id: @user.id }, time)
          
          return { token: token, exp: time.strftime('%m-%d-%Y %H:%M'), user: Shared::UserSerializer.new(@user) }
        else
          raise StandardError.new("Unauthorized")
        end
      end
    end

    def rafflers
      return "Can't show riferos, user are not taquilla or admin." unless %w[Taquilla Admin].include?(role)

      case role
      when 'Taquilla'
        Shared::User.where(id: rifero_ids)
      when 'Admin'
        Shared::User.where(role: 'Rifero')
      end
    end    
    
    def influencer_details
      roles_allowed = %w[Admin Influencer]

      return "Can't show influencer details, user are not influencer." unless role.in?(roles_allowed)

      return {
        user: Shared::UserSerializer.new(self),
        badges: self.role === 'Influencer' ? social_influencer.social_badges : [],
        social_networks: self.role === 'Influencer' ? social_influencer.social_networks : [],
        social_payment_options: self.role === 'Influencer' ? social_influencer.social_payment_options : []
      }
    end

    def add_seller(id)
      @seller = Shared::User.find(id)

      raise NotAllowedException.new unless self.role == 'Taquilla'
      raise NotAllowedException.new "Seller already registered", "unprocessable_entity", 22 if self.rifero_ids.include?(id)
      raise NotAllowedException.new "Seller don't exist", "not_found", 33 if @seller.nil?
      raise NotAllowedException.new "This user is not a seller", "forbidden", 44 unless @seller.role == 'Rifero'
      
      self.rifero_ids = self.rifero_ids << id
      self.save
    end

    def sellers
      raise NotAllowedException.new "Can't show sellers, user are not taquilla or admin." unless %w[Taquilla Admin].include?(role)

      case role
      when 'Taquilla'
        Shared::User.where(id: rifero_ids)
      when 'Admin'
        Shared::User.where(role: 'Rifero')
      end
    end


    def self.has_role?(role)
      Shared::User.where(role:).count.positive?
    end

    def has_role?(role)
      self.role == role
    end

    def wallet
      shared_wallet
    end

    private

    def validate_riferos
      return unless role != 'Taquilla' && rifero_ids.length.positive?

      errors.add(:rifero_ids, 'Cannot add riferos')
    end

    def generate_slug
      self.slug = name.parameterize
    end

    def generate_influencer
      if role == 'Influencer'
        Social::Influencer.create(content_code: name.parameterize.split("-").join, shared_user_id: id)
        self.is_first_entry = true
        save
      end
    end

    def generate_wallet
      Shared::Wallet.create(shared_user_id: id)
    end
  end
end
