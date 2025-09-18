class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@scorepad.site'
  layout "mailer"
end
