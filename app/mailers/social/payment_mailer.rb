class Social::PaymentMailer < ApplicationMailer
  default :from => 'noreply@cdapuestas.com'

  def pre_order_email(client, raffle, amount, currency)
    @greeting = "Hola, #{client.name} 👋🏻"
    @client = client
    @raffle = raffle
    @amount = amount 
    @currency = currency

    mail(
      to: client.email, 
      subject: "Pre orden de tu compra: #{raffle.title}",
    )
  end

  def order_email(email, raffle, amount, currency, tickets)
    @greeting = "Hola 👋🏻"
    @client = client
    @raffle = raffle
    @amount = amount 
    @tickets = tickets
    @currency = currency

    mail(
      to: email, 
      subject: "Confirmación de tu compra: #{raffle.title}",
    )
  end
end
