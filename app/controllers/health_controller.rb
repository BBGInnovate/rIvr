class HealthController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:create]
    
#    before_filter :authorize, :only=>[:index]
    before_filter :populate
    
    active_scaffold :health do |config|
      config.create.refresh_list = true
      config.update.refresh_list = true
      config.delete.refresh_list = true
      config.label = 'Health Monitor'
      # config.actions.exclude :create
      config.list.sorting = {:branch => 'ASC'}
      config.columns = [:status, :branch, :last_event, :event, :send_alarm, :no_activity, :deliver_method, :email, :cell_phone, :phone_carrier]
      config.list.columns.exclude [:no_activity, :deliver_method, :email, :cell_phone, :phone_carrier]
      config.update.columns.exclude [:branch, :last_event, :event, :status]
      config.create.columns.exclude [:last_event, :event, :status]
      config.columns[:send_alarm].label = 'Alarm Enabled'
#      config.list.columns.exclude :send_alarm
      config.columns[:no_activity].description = 'In hours to trigger notification'
      config.columns[:cell_phone].description = 'Number only'
      config.columns[:last_event].label = 'Last Event'
      # config.search.text_search = :start
      # config.search.columns = [:name]
      config.actions.exclude :search
      # config.actions.exclude :show
      config.action_links.add 'options',
                     :label => 'Configure',
                     :type => :collection,
                     :controller=>"/configure",
                     :action=>"index",
                     :page => true,
                     :inline => false

       config.action_links.add 'events',
                 :label => 'Events',
                 :type => :collection,
                 :controller=>"/events",
                 :action=>"index",
                 :page => true,
                 :inline => false
       config.action_links.add 'Entries',
                     :label => 'Moderation',
                     :type => :collection,
                     :controller=>"/entries",
                     :action=>"index",
                     :page => true,
                     :inline => false
                     
     # config.action_links << ActiveScaffold::DataStructures::ActionLink.new('alarm', :label => 'Send Alarm',:type => :member, :inline => false, :position => true)
    end
    
    def alarm
      Health.send_notification
    end
    
    def populate
      sql = "SELECT t1.id, branch, action_id, created_at FROM events as t1 JOIN (SELECT MAX(id) id FROM events GROUP BY branch) as t2 ON t1.id = t2.id;"
      events = Health.connection.execute sql
      actions = Action.all
      events.each_entry do |e|
        act = actions.select{|a| a.id==e[2]}[0]
        b = Health.find_by_branch e[1]
        if b && act
          b.update_attributes :event_id=>e[0], :last_event=>e[3], :event=>act.name
        elsif act
          Health.create :branch=>e[1], :event_id=>e[0], :last_event=>e[3], :event=>act.name
        end
      end
    end
    
    protected
     def sendlarm
       
     end
end