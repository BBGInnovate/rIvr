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
    config.columns = [:name, :country, :is_active,:description]
    config.columns[:country].label = 'Country'
    config.columns[:description].form_ui = :textarea
    # config.search.text_search = :start
    # config.search.columns = [:name]
    config.actions.exclude :search
    config.list.columns.exclude [:id, :description]
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