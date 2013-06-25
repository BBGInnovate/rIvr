class ApplicationController < ActionController::Base
  protect_from_forgery
  ActiveScaffold.set_defaults do |conf|
    conf.list.per_page = 40
  end
  def authorize
    return if DropboxSession.last
    if params[:oauth_token] then
      dropbox_session = Dropbox::Session.deserialize(session[:dropbox_session])
      dropbox_session.authorize(params)
      dropbox = DropboxSession.new
      dropbox.token=dropbox_session.token
      dropbox.secret=dropbox_session.secret
      dropbox.save
      session[:dropbox_session] = dropbox_session.serialize
      # re-serialize the authenticated session
      redirect_to '/'
    else
      dropbox_session = Dropbox::Session.new(DROPBOX[:consumer_key], DROPBOX[:consumer_secret])
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
end
