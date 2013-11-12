class ActiveRecord::Base
  # cattr_accessor :dropbox_session
  @@dropbox_session = nil
  
  def self.get_dropbox_session
    ds = DropboxSession.last
    if !!ds
      @@dropbox_session = Dropbox::Session.new(DROPBOX.consumer_key, DROPBOX.consumer_secret)
      @@dropbox_session.set_access_token ds.token, ds.secret
      @@dropbox_session.mode = :dropbox
    else
      @@dropbox_session = nil
    end
    @@dropbox_session
  end
  def self.dropbox_session
    @@dropbox_session || get_dropbox_session
  end
  
  def get_dropbox_session
    ds = DropboxSession.last
    if !!ds
      @dropbox_session = Dropbox::Session.new(DROPBOX.consumer_key, DROPBOX.consumer_secret)
      @dropbox_session.set_access_token ds.token, ds.secret
      @dropbox_session.mode = :dropbox
    else
      @dropbox_session = nil
    end
    @dropbox_session
  end
  
  # Return the first object which matches the attributes hash
  # - or -
  # Create new object with the given attributes
  #
  def self.find_or_create(attributes)
    where(attributes).last || create(attributes)
  end

end
module Kernel
private
    def this_method_name
      caller[0] =~ /`([^']*)'/ and $1
    end
end