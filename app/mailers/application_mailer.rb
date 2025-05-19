# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@cdapuestas.com'
  layout 'mailer'

  def welcome_email
    @url  = "http://example.com/login"
    mail(to: 'javierdiazt406@icloud.com', subject: "Welcome to My Awesome Site")
  end
end
