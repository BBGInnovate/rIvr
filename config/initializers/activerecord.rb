class ActiveRecord::Base
  def get_dropbox_session
    ds = DropboxSession.last
    if !!ds
      dropbox_session = Dropbox::Session.new(DROPBOX.consumer_key, DROPBOX.consumer_secret)
      dropbox_session.set_access_token ds.token, ds.secret
      dropbox_session.mode = :dropbox
    else
      dropbox_session = nil
    end
    dropbox_session
  end
end