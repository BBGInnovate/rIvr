class EventsController < ApplicationController
#  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  
#  before_filter :authorize, :only=>[:index]
  active_scaffold :event do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.label = 'Event Log'
    config.actions.exclude :create
    config.list.sorting = {:id => 'DESC'}
    config.columns = [:branch, :session_id, :caller_id, :page, :action, :identifier, :created_at]
    config.search.text_search = :start
    config.search.columns = [:branch, :caller_id]
    # config.list.columns.exclude [:identifier]
    config.actions.exclude :update
    config.actions.exclude :create
        
    config.action_links.add 'Entries',
                         :label => 'Moderation',
                         :type => :collection,
                         :controller=>"/entries",
                         :action=>"index",
                         :page => true,
                         :inline => false
#    config.action_links.add 'options',
#           :label => 'Options',
#           :type => :collection,
#           :controller=>"/options",
#           :action=>"index",
#           :page => true,
#           :inline => false
          
  end
end