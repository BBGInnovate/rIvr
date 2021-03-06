class BranchesController < ApplicationController
#  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  
#  before_filter :authorize, :only=>[:index]
  active_scaffold :branch do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.label = 'Branch'
    # config.actions.exclude :create
    config.list.sorting = {:id => 'ASC'}
    config.columns = [:name, :client_ip_address, :message_time_span, :country_flag_url, :contact, :ivr_call_number, :gmaps, :latitude, :longitude, :vote_result, :country, :is_active, :forum_type, :description]
    config.columns[:country].label = 'Country'
    config.columns[:description].form_ui = :textarea
    # config.search.text_search = :start
    # config.search.columns = [:name]
    config.actions.exclude :search
    config.list.columns.exclude [:client_ip_address, :message_time_span,:country_flag_url, :contact, :ivr_call_number,:gmaps,:latitude, :longitude,:id, :description]
    config.create.columns.exclude [:vote_result]
    config.update.columns.exclude [:vote_result]
      
    config.actions.exclude :show
    config.action_links.add 'configure',
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
               
#        config.action_links.add 'healthes',
#                   :label => 'Health',
#                   :type => :collection,
#                   :controller=>"/health",
#                   :action=>"index",
#                   :page => true,
#                   :inline => false
         config.action_links.add 'Entries',
                         :label => 'Moderation',
                         :type => :collection,
                         :controller=>"/entries",
                         :action=>"index",
                         :page => true,
                         :inline => false
  end
  def before_create_save(record)
     record.country_id = params[:record][:country_id]
  end
  def before_update_save(record)
     record.country_id = params[:record][:country_id]
  end
end