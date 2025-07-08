# == Schema Information
#
# Table name: social_clients
#
#  id         :bigint           not null, primary key
#  address    :string
#  country    :string
#  dni        :string
#  email      :string
#  name       :string
#  phone      :string
#  province   :string
#  zip_code   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Social::Client < ApplicationRecord
  # ------ Associations/relationships between tables
  # has_many :social_orders, class_name: 'Social::Order', foreign_key: 'social_client_id', dependent: :destroy

  # ------ Validations
  validates :name, 
            presence: true,
            length: { minimum: 3, maximum: 50 },
            if: -> { name.length > 0 }

  validates :email,
            format: {
              with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i,
              message: 'Introduzca un correo electrónico válido'
            },
            if: -> { email.length > 0 }

  validates :phone, 
            presence: {
              message: 'Debe introducir un número de teléfono'
            },
            uniqueness: {
              message: 'Ya existe un cliente con este número de teléfono'
            },
            format: {
              with: /\A\+\d{1,4} \(\d{1,4}\) \d{1,10}-\d{1,10}\z/,
              message: 'Introduzca un número de teléfono válido en el formato: +prefijo telefónico (codigo de area) tres primeros dígitos - dígitos restantes, por ejemplo: +58 (416) 000-0000'
            }
  
  validates :country,
            presence: true,
            inclusion: {
              in: ['Venezuela', 'Colombia', 'Perú', 'Ecuador', 'Chile', 'Argentina', 'Uruguay', 'Paraguay', 'Bolivia', 'Brasil', 'México', 'USA', 'Canadá']
            }

  validates :province,
            length: { minimum: 3, maximum: 50 },
            if: -> { province.length > 0 }

  validates :zip_code,
            length: { minimum: 3, maximum: 10 },
            if: -> { zip_code.length > 0 }

  validates :address,
            length: { minimum: 3, maximum: 120 },
            if: -> { address.length > 0 }

  # ------ Public methods
  def methods
    social_payment_methods
  end
end
