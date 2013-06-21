class PagesController < ApplicationController
#  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  
  before_filter :authorize, :only=>[:index]
  active_scaffold :page do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.label = 'Page'
    # config.actions.exclude :create
    config.list.sorting = {:id => 'ASC'}
    config.columns = [:id, :name]
    # config.search.text_search = :start
    # config.search.columns = [:name]
    config.actions.exclude :search
    # config.list.columns.exclude [:identifier]
    config.actions.exclude :show

  end
end