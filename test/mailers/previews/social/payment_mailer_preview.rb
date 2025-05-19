# test/mailers/previews/social/payment_mailer_preview.rb
class Social::PaymentMailerPreview < ActionMailer::Preview
  def pre_order_email
    client = Social::Client.first # or create a mock client
    raffle = Social::Raffle.first # or create a mock raffle
    amount = 10.00 # or any other amount you want to test with
    currency = "USD" # or any other currency you want to test with
    Social::PaymentMailer.pre_order_email(client, raffle, amount, currency)
  end
end