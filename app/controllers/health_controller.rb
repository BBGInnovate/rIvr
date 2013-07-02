class HealthController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:create]
    
    before_filter :authorize, :only=>[:index]
    before_filter :populate
    
    active_scaffold :health do |config|
      config.create.refresh_list = true
      config.update.refresh_list = true
      config.delete.refresh_list = true
      config.label = 'Branch Health'
      # config.actions.exclude :create
      config.list.sorting = {:branch => 'ASC'}
      config.columns = [:branch, :last_event, :action]
      config.columns[:last_event].label = 'Last Event'
      # config.search.text_search = :start
      # config.search.columns = [:name]
      config.actions.exclude :search
      config.actions.exclude :show
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
    end
    
    def populate
      sql = "SELECT t1.id, branch, action_id, created_at FROM events as t1 JOIN (SELECT MAX(id) id FROM events GROUP BY branch) as t2 ON t1.id = t2.id;"
      events = Health.connection.execute sql
      actions = Action.all
      Health.truncate
      events.each_entry do |e|
        act = actions.select {|a| a.id==e[2]}
        puts "branch: #{e[1]} action: #{act[0].name} time: #{e[3]}"
        Health.create :branch=>e[1], :event_id=>e[0], :last_event=>e[3], :action=>act.name
      end
    end
end