class ApplicationController < ActionController::Base
  protect_from_forgery
  
#  before_filter :authenticate_user!
  before_filter :init
  before_filter :add_klass
  layout :choose_layout
  def choose_layout
    if @controller != 'moderation'
      erb ='application'
    else
      erb = 'moderation'
    end
    !params[:ajax] ? erb : nil
  end
    
  ActiveScaffold.set_defaults do |conf|
    conf.list.per_page = 40
  end
  def authorize
    # comment next line if you want to re-authenticate user
    # return if DropboxSession.last
    if params[:oauth_token] then
      dropbox_session = Dropbox::Session.deserialize(session[:dropbox_session])
      dropbox_session.authorize(params)
      dropbox = DropboxSession.new
      dropbox.token=dropbox_session.access_token.token
      dropbox.secret=dropbox_session.access_token.secret
      dropbox.save
      session[:dropbox_session] = dropbox_session.serialize
      # re-serialize the authenticated session
      redirect_to '/'
    else
      dropbox_session = Dropbox::Session.new(DROPBOX.consumer_key, DROPBOX.consumer_secret)
      session[:dropbox_session] = dropbox_session.serialize
      redirect_to dropbox_session.authorize_url(:oauth_callback => url_for(:action => 'authorize'))
    end
  end
  
  def url_available?(url_str)
    begin
      url = URI.parse(url_str)
      Net::HTTP.start(url.host, url.port) do |http|
      return http.head(url.request_uri).code == "200"
    end
    rescue
      return false
    end
  end
  # add class to nav bar box
  def add_klass
    @klass = params[:klass]
  end
  def init
    @controller = request.filtered_parameters['controller']
       started = Branch.message_time_span.days.ago.to_s(:db)
       ended = Time.now.to_s(:db)
       @alerts = Stat.new(started, ended).alerted
       @messages = Stat.new(started, ended).messages
       @calls = Stat.new(started, ended).number_of_calls
       @controller = request.filtered_parameters['controller']
  end
end
