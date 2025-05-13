

def rifas_ticket
  serial_generado = rand(1_000_000_000)
  numero_ticket = NumeroTicket.find_by(estructura_id: @estructura.id).increment!(:numero).numero
  body = "[table]Numero|Precio[/table]#{@salto_linea}"
  
  @details.each do |numero|
    body += "[table]#{numero['position']}|#{@transaction.currency} #{numero['price'].to_f.round(2)}[/table]#{@salto_linea}"
  end

  body += "[LINE]#{@salto_linea}"
  body += "[center][bold]Datos de la rifa:[/bold][/center]#{@salto_linea}"
  body += "[center]#{@transaction.x100_raffle['title']}[/center]#{@salto_linea}"
  body += "[center]#{@transaction.x100_raffle['raffle_type']} #{@transaction.x100_raffle['tickets_count'].positive? ? @transaction.x100_raffle['tickets_count'] : ''} - #{@transaction.x100_raffle['lotery']}[/center]#{@salto_linea}"
  body += "[center]Tipo Rifa: #{@transaction.x100_raffle['draw_type']}#{@transaction.x100_raffle['tickets_count'].positive? ? @transaction.x100_raffle['tickets_count'] : '10.000'} Numeros[/center]#{@salto_linea}"
  body += "[center]Probabilidad: 1/#{@transaction.x100_raffle['tickets_count'].positive? ? @transaction.x100_raffle['tickets_count'] : '10.000'} Numeros[/center]#{@salto_linea}"
  body += "[LINE]#{@salto_linea}"

  ticket_string = ticket_head(serial_generado, numero_ticket) + body + ticket_footer(@transaction.amount, nil)

  params = { ticket_string: ticket_string,
             plays: @details,
             monto: @transaction.amount,
             win: '',
             game: 'rifas',
             serial: serial_generado,
             numero_ticket: numero_ticket,
             codagen: @estructura.id,
             company_id: @estructura.company_id,
             cajero_id: @wallet_id }

  sent_ticket_to_centinela(params) if @tx_type == 'DEBIT'

  [ticket_string, numero_ticket]
end