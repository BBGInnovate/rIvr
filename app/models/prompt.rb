# require 'file_column'
class Prompt < ActiveRecord::Base
  file_column :sound_file
  validates :branch, :presence => true, :length => { :maximum => 50 }
  validates :name, :presence => true, :length => { :maximum => 255 }
  validates :sound_file, :presence => true, :length => { :maximum => 255 }
    
  def upload_file=(file_field)
    file = file_field.original_filename
    self.content_type = file_field.content_type.chomp
    ds = DropboxSession.last
    if !!ds
      client = get_dropbox_session
      to = "/Public/#{self.branch}/"
      from = file_field.tempfile
      begin
        self.url = DROPBOX[:public_dir] + "/#{self.branch}/#{file}"
#        content = client.upload(from, to)
        FileUtils.cp(file_field.tempfile.path, '/tmp/' + file_field.original_filename)
        file_field.tempfile.unlink
        client.upload '/tmp/' + file_field.original_filename, 'Public/oddi/'
              
                
      rescue Exception => msg
        if msg.kind_of? Dropbox::FileNotFoundError
          self.url = nil
        elsif msg.kind_of? Timeout::Error
          self.url = nil
        end
        logger.debug "Error upload #{from} #{to} : #{msg}"
      end
    end
  end

  protected
  def base_part_of(file_name)
    File.basename(file_name).gsub(/[^\w._-]/,'')
  end

  def get_dropbox_session
      ds = DropboxSession.last
      if !!ds
        dropbox_session = Dropbox::Session.new(DROPBOX[:consumer_key], DROPBOX[:consumer_secret])
        dropbox_session.set_access_token ds.token, ds.secret
        dropbox_session.mode = :dropbox
      else
        nil
      end
      # token = dropbox_session.access_token
      # res = token.post "https://api.dropbox.com/1/shares/dropbox/bbg/oddi/Desert.jpg"
      # json = JSON.parse res.body
      # shared_link = json['url']
      dropbox_session
  end
end