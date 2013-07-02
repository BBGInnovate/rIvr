class UserMailer < ActionMailer::Base
  default :from => "doug@bbg.gov"  
  # UserMailer.welcome_email(user).deliver worked
  def alarm_email(user, branch)
      @user = user
      @url  = 'http://ivr.bbg.gov'
      mail(to: @user.email, subject: "No Activity in Branch #{branch} For 6 Hours!")
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
