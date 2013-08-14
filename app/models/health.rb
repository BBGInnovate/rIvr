class Health< ActiveRecord::Base
  attr_accessor :status
  belongs_to :branch
  self.table_name = "healthes"
  def to_label
    "Health"
  end
  
  # # this command will run at 12:05, 1:05, etc.
  # 5 * * * * export RAILS_ENV=staging && cd /data/ivr/current && rails runner  "Health.send_notification" >/dev/null 2>&1
  def self.send_notification
    sms_fu = SMSFu::Client.configure(:delivery => :action_mailer)
    Health.all.each do |h|
      next if !h.last_event
      seconds = (Time.now.to_i - h.last_event.to_i)
      hours = seconds/3600.to_i
      minutes = (seconds/60 - hours * 60).to_i
      if h.send_alarm && ( seconds > h.no_activity*3600)
        message = "Branch #{h.branch.name}: No Activity For #{hours} hours and #{minutes} minutes"
        if h.deliver_method == "email"
          UserMailer.alarm_email(h, message).deliver if h.email
          logger.debug "SENT #{h.email} #{message}"
        else
          if h.cell_phone && h.phone_carrier
            sms_fu.deliver(h.cell_phone, h.phone_carrier, message)
            logger.debug "SENT #{h.cell_phone} #{message}"
          end
        end
      end
    end
  end
  
  def authorized_for_alarm?
     mail = (self.deliver_method == 'email' && self.email)
     text = (self.deliver_method == 'text' && self.cell_phone && self.phone_carrier)
     self.send_alarm && (mail || text)
  end
  
  def self.truncate
      connection.execute "truncate table #{table_name}"
  end
end