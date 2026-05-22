class ConfirmationMailer < ApplicationMailer
  def confirmation(user)
    @user = user
    @confirm_url = confirm_registration_url(token: user.confirmation_token)
    mail(to: user.email_address, subject: "Confirm your RubyCell account")
  end
end
