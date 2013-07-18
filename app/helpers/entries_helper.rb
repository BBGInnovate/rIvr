module EntriesHelper

  def created_at_column(record, column=nil)
    record.created_at.strftime("%Y/%m/%d %H:%M:%S")
  end
  def updated_at_column(record, column=nil)
    record.updated_at.strftime("%Y/%m/%d %H:%M:%S")
  end
  def dropbox_file_column(record, column=nil)
#    ds = DropboxSession.last
#    dropbox_session = Dropbox::Session.new('0pk3wj3qyq7be7q', 'v6ujmd2ywlcgtq7')
#    dropbox_session.set_access_token ds.token, ds.secret
#    dropbox_session.mode = :dropbox
#    link = dropbox_session.link(record.file_path)
#    User.logger.debug "AAAAA #{link.inspect}"
#    link_to record.dropbox_file, link, :target => '_blank'
#    
    link_to record.dropbox_file, play_entry_path(record), :target => '_blank'
  end
  def public_url_column(record, column=nil)
    if !record.is_private?
      link_to record.dropbox_file, record.public_url, :target => '_blank'
    else
      nil
    end
   end
    
  def soundcloud_url_column(record, column=nil)
    if !!record.soundcloud_url
      f = record.soundcloud_url.split("/").last
      link_to f, record.soundcloud_url, :target => '_blank'
    else
      nil
    end
  end
  
  def is_private_column(record, column=nil)
    !!record.is_private ? "Yes" : "No"
  end
end