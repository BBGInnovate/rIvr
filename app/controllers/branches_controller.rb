class BranchesController < ApplicationController
#  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  
  before_filter :authorize, :only=>[:index]
  active_scaffold :branch do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.label = 'Branch'
    # config.actions.exclude :create
    config.list.sorting = {:id => 'ASC'}
    config.columns = [:name, :country, :description]
    config.columns[:country].label = 'Country'
    config.columns[:description].form_ui = :textarea
    # config.search.text_search = :start
    # config.search.columns = [:name]
    config.actions.exclude :search
    config.list.columns.exclude [:id, :description]
    # config.actions.exclude :show
    config.action_links.add 'configure',
          :label => 'Configure',
          :type => :collection,
          :controller=>"/configure",
          :action=>"index",
          :page => true,
          :inline => false
  end
end