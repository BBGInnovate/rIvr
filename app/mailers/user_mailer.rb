class UserMailer < ActionMailer::Base
  default :from => "doug@bbg.gov"  
  # UserMailer.alarm_email(health, message).deliver worked
  def alarm_email(health, message)
      @health = health
      @message = message
      mail(to: @health.email, subject: @message)
  end

  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @url  = "http://YOURSITE/activate/#{user.activation_code}"
    mail(to: @user.email, subject: @subject)
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @url  = "http://YOURSITE/"
    mail(to: @user.email, subject: @subject)
  end
  
  protected

  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = "ADMINEMAIL"
    @subject     = "[YOURSITE] "
    @sent_on     = Time.now
    @user = user
  end

end
