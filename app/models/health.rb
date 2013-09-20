class Health< ActiveRecord::Base
  attr_accessor :status
  belongs_to :branch
  self.table_name = "healths"
  def to_label
    "Health"
  end
  
  # # this command will run at 12:05, 1:05, etc.
  # 5 * * * * export RAILS_ENV=staging && cd /data/ivr/current && rails runner  "Health.send_notification" >/dev/null 2>&1
  def self.send_notification
    Health.populate
    
    sms_fu = SMSFu::Client.configure(:delivery => :action_mailer)
    Health.all.each do |h|
      next if !h.last_event
      seconds = (Time.now.to_i - h.last_event.to_i)
      hours = seconds/3600.to_i
      minutes = (seconds/60 - hours * 60).to_i
      if h.send_alarm && ( seconds > h.no_activity*3600)
        branch = Branch.find_by_id h.branch_id
        if branch
          branch.status = "No Activity"
          branch.save
        end
        message = "Branch #{h.branch.name}: No Activity For #{hours} hours and #{minutes} minutes"
        if h.deliver_method == "email"
          if h.email
            UserMailer.alarm_email(h, message).deliver
            logger.debug "SENT #{h.email} #{message}"
            AlertedMessage.create :branch_id=>h.branch_id,
              :message=>message,
              :delivered_to=>h.email
          end
        else
          if h.cell_phone && h.phone_carrier
            sms_fu.deliver(h.cell_phone, h.phone_carrier, message)
            logger.debug "SENT #{h.cell_phone} #{message}"
            AlertedMessage.create :branch_id=>h.branch_id,:message=>message,
                :delivered_to=>h.cell_phone
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
  
  
  def self.populate(branches=nil)
        sql = "SELECT t1.id, branch_id, action_id, created_at FROM events as t1 JOIN (SELECT MAX(id) id FROM events WHERE action_id != #{Action.ping_server} GROUP BY branch_id) as t2 ON t1.id = t2.id;"
        events1 = Health.connection.execute sql
        # next to find ping server event
#        sql2 = "SELECT t1.id, branch_id, action_id, created_at FROM events as t1 JOIN (SELECT MAX(id) id FROM events WHERE action_id = #{Action.ping_server} GROUP BY branch_id) as t2 ON t1.id = t2.id;"
#        events2 = Health.connection.execute sql2
        # find ping server event does not count
        events2 = []
        events = events1.to_a + events2.to_a
        actions = Action.all
        branch_ids = []
        events.each do |e|
          br  = Branch.find_me e[1]
          branch_ids << br
          next if (!br || !br.is_active)
          act = actions.select{|a| a.id==e[2]}[0]
          b = Health.find_by_branch_id e[1]
          if b && act
            b.update_attributes :event_id=>e[0], :last_event=>e[3], :event=>act.name
          elsif act && act.id != Action.ping_server
            Health.create :branch_id=>e[1], :event_id=>e[0], :last_event=>e[3], :event=>act.name
          end
        end
        branch_ids.compact!
        if !branches
          branches = Branch.where(["is_active=1 AND id not in (?)", branch_ids])
        end
        branches.each do |b|
          if !Health.find_by_branch_id(b.id)
            Health.create :branch_id=>b.id
          end
        end    
   end
      
  def self.truncate
      connection.execute "truncate table #{table_name}"
  end
end