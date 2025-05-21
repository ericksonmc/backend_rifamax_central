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

  def order_email(client, payment)
    @greeting = "Hi"

    mail to: "to@example.org"
  end
end
