class EntriesController < ApplicationController
#  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  
  #  before_filter :dropbox_session, :only=>[:index]
  # before_filter :authorize, :only=>[:index]
  active_scaffold :entry do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.label = 'Moderation'
#    config.actions.exclude :create
    config.list.sorting = {:id => 'DESC'}
    config.columns = [:branch, :forum_type, :public_url, :dropbox_file, :length, :soundcloud_url, :dropbox_dir, :phone_number, :is_private, :created_at, :updated_at]
#    config.search.text_search = :start
#    config.search.columns = [:branch, :dropbox_file]
    config.actions.exclude :search
    config.columns[:phone_number].label = 'Phone'
    config.list.columns.exclude [:created_at, :dropbox_dir, :length, :phone_number]
    config.update.columns.exclude [:branch,:forum_type,:created_at, :dropbox_dir, :length, :phone_number]
      
    config.action_links.add 'configure',
               :label => 'Configure',
               :type => :collection,
               :controller=>"/configure",
               :action=>"index",
               :page => true,
               :inline => false
    config.action_links.add 'branches',
                   :label => 'Branch',
                   :type => :collection,
                   :controller=>"/branches",
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
           
    config.action_links.add 'soundcloud',
           :label => "<span title='Upload to SoundCloud'>SoundCloud</span>".html_safe,
           :type => :member,
           :inline => false,
           :page => true,
           :security_method=> :display?
                   
#    config.action_links.add 'health',
#               :label => 'Health',
#               :type => :collection,
#               :controller=>"/health",
#               :action=>"index",
#               :page => true,
#               :inline => false
    
  end
  
  def display?(record=nil)
    if record
      !!record.public_url
    else
      true
    end
  end
  
  def soundcloud
    if params[:cancel]
      redirect_to "/entries" and return
    end
    id = params[:id]
    @entry = Entry.find_by_id id
    if @entry.soundkloud
      @soundcloud = @entry.soundkloud
    else
      @soundcloud = Soundkloud.new
    end
    
    @result = nil
    if request.post?
      s = params[:soundcloud]
      @soundcloud.title = s[:title]
      @soundcloud.genre = s[:genre]
      @soundcloud.description=s[:description]
      if @soundcloud.valid?
        @result = @entry.copy_to_soundcloud @soundcloud
      else   
        @result = @soundcloud.errors.full_messages
      end
    end
  end
  
  def play
    ds = DropboxSession.last
    if !!ds
      dropbox_session = Dropbox::Session.new(DROPBOX.consumer_key, DROPBOX.consumer_secret)
      dropbox_session.set_access_token ds.token, ds.secret
      dropbox_session.mode = :dropbox
      e = Entry.find_by_id params[:id]
      return '' if !e
      # mime_type posted by IVR system may not be correct
      meta = dropbox_session.metadata("bbg/#{e.branch.name}/#{e.dropbox_file}")
      e.mime_type = meta.mime_type
      e.size = meta.bytes
 #     e.save
      
      content = dropbox_session.download("bbg/#{e.branch.name}/#{e.dropbox_file}")
      send_data content,
      :filename=>e.dropbox_file,
      :type=>e.mime_type,
      :disposition=>'inline'
    end
  end
#  def create
#    attr = params[:entry]
#    if attr
#      e = Entry.find_by_dropbox_file attr[:dropbox_file]
#      if e
#        e.updated_at = Time.now
#        e.update_attributes attr
#      else
#        Entry.create attr
#      end
#    else
#      logger.info "params[:entry] : #{params[:entry]}"
#    end
#    render :nothing=>true
#  end
  
  def show_dropbox_file_old
    ds = DropboxSession.last
    if !!ds
      @client=Dropbox::API::Client.new(:token=>ds.token,:secret =>ds.secret)
      e = Entry.find_by_id params[:id]
      return '' if !e
      dir = "#{e.dropbox_dir}/#{e.dropbox_file}"
      content = @client.download("bbg/#{e.branch}/#{e.dropbox_file}")
      send_data content,
      :filename=>e.dropbox_file,
      :type=>contenttype(e.dropbox_file),
      :disposition=>'inline'
    end
  end

  def after_update_save(record)
     @href = "/entries/#{record.id}/play"
     flash[:error] = "#{record.errors.messages[:base][0]}" if record.errors.messages[:base]
  end
    
  protected

  # Overrides the standard delete functionality for ActiveScaffold so that 
  # records are removed by being marked as "Inactive" rather than being 
  # physically deleted.
  def do_destroy
    @record = Entry.find_by_id(params[:id])
    @record.is_active = false
    self.successful = @record.save
  end
      
  def contenttype(file)
    arr = file.split(".")
    if arr.last == "wav"
      'audio/wav'
    else
      'audio/mpeg'
    end
  end

end