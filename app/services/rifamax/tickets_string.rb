# == Schema Information
#
# Table name: rifamax_tickets
#
#  id                     :bigint           not null, primary key
#  is_sold                :boolean
#  is_winner              :boolean
#  number                 :integer
#  number_position        :integer
#  uniq_identifier_serial :string
#  wildcard               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  raffle_id              :bigint           not null
#
# Indexes
#
#  index_rifamax_tickets_on_raffle_id  (raffle_id)
#
# Foreign Keys
#
#  fk_rails_...  (raffle_id => rifamax_raffles.id)
#

# frozen_string_literal: true

class Rifamax::TicketsString
  PRINTER_VIEWPORT = 80
  CHARS_PER_LINE = 48

  def initialize(tickets)
    @tickets = tickets
  end

  def generate_strings
    @tickets.map { |ticket| build_ticket(ticket) }
  end

  private

  def build_ticket(ticket)
    main_prize = first_prize
    days_left = days_until_expiration

    lines = []
    lines << double_line
    lines << center('RIFAMAX')
    lines << double_line
    lines << pad_between("  N° #{format('%03d', ticket.number.to_i)}", "Precio: #{format_price(raffle.price, raffle.currency)}  ")
    lines << ''
    lines << center("Signo: #{ticket.wildcard}") if ticket.wildcard.present?
    lines << labeled('Premio', main_prize[:award])
    lines << labeled('Sin Signo', main_prize[:plate]) if main_prize[:plate].present?
    lines << ''
    lines << center("Caduca en #{days_left} día#{'s' if days_left != 1}. Escanee aquí:")
    lines << center("[QR:#{ticket.uniq_identifier_serial}]")
    lines << single_line
    lines << labeled('Agencia',  agency_name)
    lines << labeled('Serie',    serie_code)
    lines << labeled('Fecha',    raffle.created_at&.strftime('%d/%m/%Y'))
    lines << labeled('Hora',     raffle.created_at&.strftime('%I:%M %p'))
    lines << labeled('Lotería',  raffle.lotery)
    lines << labeled('Rifero',   rifero_name)
    lines << labeled('Teléfono', rifero_phone)
    lines << double_line
    lines.join("\n")
  end

  def labeled(label, value)
    "#{(label + ':').ljust(11)}#{value}".slice(0, CHARS_PER_LINE)
  end

  def first_prize
    return { award: 'Sin premio', plate: nil } if raffle.prizes.blank?

    prize = raffle.prizes.first
    return { award: prize.to_s, plate: nil } unless prize.is_a?(Hash)

    {
      award: prize['award'] || prize[:award],
      plate: prize['plate'] || prize[:plate]
    }
  end

  def days_until_expiration
    return 0 if raffle.expired_date.blank?

    diff = (raffle.expired_date - Date.today).to_i
    diff.negative? ? 0 : diff
  end

  def agency_name
    raffle.user&.name
  end

  def rifero_name
    raffle.seller&.name
  end

  def rifero_phone
    raffle.seller&.phone
  end

  def serie_code
    raffle.uniq_identifier_serial.to_s[-4..] || raffle.id.to_s
  end

  def center(text)
    text = text.to_s
    return text if text.length >= CHARS_PER_LINE

    padding = (CHARS_PER_LINE - text.length) / 2
    (' ' * padding) + text
  end

  def pad_between(left, right)
    left = left.to_s
    right = right.to_s
    gap = CHARS_PER_LINE - left.length - right.length
    gap = 1 if gap < 1
    left + (' ' * gap) + right
  end

  def single_line
    '-' * CHARS_PER_LINE
  end

  def double_line
    '=' * CHARS_PER_LINE
  end

  def format_price(price, currency)
    return '-' if price.nil?

    "#{format('%.2f', price)} #{currency}"
  end

  def raffle
    @raffle ||= @tickets.first&.raffle || Rifamax::Raffle.find(@tickets.first.raffle_id)
  end
end
