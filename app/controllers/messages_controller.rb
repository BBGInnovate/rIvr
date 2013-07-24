class MessagesController < ApplicationController
#  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  
#  before_filter :authorize, :only=>[:index]
  active_scaffold :message do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.actions.exclude :show
    config.columns = [:name, :description ]
    config.columns[:description].form_ui = :textarea
    config.columns[:description].options = {:cols=>37, :rows => 10}
    config.list.columns.exclude [:created_at, :updated_at]
    config.create.columns.exclude [:created_at, :updated_at]
    config.action_links.add 'prompts',
              :label => 'Prompts',
              :type => :collection,
              :controller=>"prompts",
              :action=>"index",
              :page => true,
              :inline => false
  end


  
  protected
  
end