class PromptsController < ApplicationController
#  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  
  before_filter :authorize, :only=>[:index]
  active_scaffold :prompt do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
#    config.actions.exclude :show
    config.columns = [:branch,:name, :sound_file, :content_type, :url, :description, :is_active]
#    config.columns[:dropbox].description = "Upload sound file to Dropbox"
    config.columns[:name].form_ui = :select
    config.columns[:description].form_ui = :textarea
    config.columns[:description].options = {:cols=>37, :rows => 10}
    config.columns[:description].description = "<span id='desc-limit'></span> characters left".html_safe
    config.columns[:url].options = {}
    config.columns[:is_active].description = "Uncheck to disable this message"
    config.list.columns.exclude [:content_type, :description]
    config.create.columns.exclude [:content_type, :url]
    config.action_links.add 'messages',
          :label => 'Message',
          :type => :collection,
          :controller=>"/messages",
          :action=>"index",
          :page => true,
          :inline => false
  end

  def before_create_save(record)
    record.upload_file = params[:record][:sound_file]
    super
  end
    
  def before_update_save(record)
    record.upload_file = params[:record][:sound_file]
    super
  end
  
  protected
  
end