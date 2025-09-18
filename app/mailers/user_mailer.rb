class UserMailer < ApplicationMailer
  def test_email(to_email)
    mail(to: to_email, subject: "Test Email from Scorepad")
  end

  def confirmation_email(user)
    @user = user
    @confirmation_url = confirm_user_url(token: @user.confirmation_token)
    mail(to: @user.email, subject: "Confirm your email for Scorepad")
  end
end
