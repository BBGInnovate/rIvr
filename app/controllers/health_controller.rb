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
      Health.populate
    end
    
    protected
     def sendlarm
       
     end
end
