require 'dropbox'
require 'open-uri'
class Entry< ActiveRecord::Base
  before_save :add_properties
  after_destroy :delete_from_dropbox
  before_save :copy_to_public
  
  HUMANIZED_COLUMNS = {:size=>"Size (bytes)"}

  def self.human_attribute_name(attribute, options = {})
    HUMANIZED_COLUMNS[attribute.to_sym] ||
    attribute.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
  end

  # When ActiveScaffold needs to present a string description of a record,
  # it searches through a common list of record properties looking for
  # something that responds. The search set, in order, is:
  # :to_label, :name, :label, :title, and finally :to_s.
  # So if your schema already has one of those fields, it’ll be automatically
  # used. But you can always define a to_label method to customize the
  # string description.
  
  def self.public_entries(caller)
    where("is_private=0 AND phone_number != #{caller}").order('id desc').limit(10).all
  end
  
  def file_path
    "/bbg/#{self.branch}/#{self.dropbox_file}"
  end

  def to_label
    "Entry"
  end
  def shared_link
    if !self.is_private && !self.public_url
      token = get_dropbox_session.access_token
      res = token.post "https://api.dropbox.com/1/shares/dropbox/#{dropbox_dir}/#{dropbox_file}"
      json = JSON.parse res.body
      self.public_url = json['url']
      self.save
    elsif self.is_private && self.public_url
      self.public_url = nil
      self.save
    end
  end
  def copy_to_public
    ds = DropboxSession.last
    if !!ds
      client = get_dropbox_session
      to = "Public/#{self.branch}/#{self.dropbox_file}"
      from = file_path
      begin
        if !self.is_private
          self.public_url = DROPBOX.public_dir + "/#{self.branch}/#{self.dropbox_file}"
          content = client.copy(from, to)
          # self.save
        elsif self.public_url
          self.public_url = nil
          client.delete(to)
          # self.save
        end
      rescue Exception => msg 
        if msg.kind_of? Dropbox::FileNotFoundError
          self.public_url = nil
        end
        logger.debug "Error copy #{from} #{to} : #{msg}"
        # do nothing
      end
    end
  end
  def copy_to_soundcloud(params)
    return if !self.public_url
    client = Soundcloud.new(:access_token => SOUNDCLOUD.access_token)
    s = params[:soundcloud]
    self.title = s[:title] || self.dropbox_file
    begin
      track = client.post('/tracks', :track=>{
        :title => self.title,
        :description=>s[:description],
        :duration=>self.length*1000,
        :downloadable => true,
        :sharing=>'public',
        :track_type=>'bbg',
        :types=>"bbg",
        :label_name=>self.dropbox_file,
        :genre=>s[:genre],
        :tag_list=>self.dropbox_dir.sub("/",' '),
        :asset_data   => open(self.public_url)
      })
      self.soundcloud_url = track.permalink_url
      self.save
      return self.soundcloud_url
    rescue
       logger.warn "Entry#copy_to_soundcloud #{$!.message}"
       return "#{$!.message}"
    end
    
  end
  
  def add_properties
    self.dropbox_dir="bbg/#{self.branch}"
  end
  
  def delete_from_dropbox
    s = get_dropbox_session
    begin
      s.delete self.file_path
    rescue Exception => msg
      logger.debug "#{msg}"
    end
    if self.soundcloud_url
      begin
        client = Soundcloud.new(:client_id =>SOUNDCLOUD.client_id)
        track = client.get('/resolve',:url=>self.soundcloud_url)
        client = Soundcloud.new(:access_token => SOUNDCLOUD.access_token)
        client.delete "/tracks/#{track.id}"
      rescue Exception => msg
        logger.debug "ERROR: resolve #{self.soundcloud_url} #{msg}"
      end
    end
  end
  
  def dropbox_dir
     read_attribute(:dropbox_dir) || "bbg/#{self.branch}"
  end

  def branch=(value)
    write_attribute :branch, value.downcase
  end
  
  protected

  def get_dropbox_session
    ds = DropboxSession.last
    if !!ds
      dropbox_session = Dropbox::Session.new(DROPBOX.consumer_key, DROPBOX.consumer_secret)
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
