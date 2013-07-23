require 'dropbox'
require 'open-uri'
class Entry< ActiveRecord::Base
  before_save :add_properties
  after_destroy :delete_from_dropbox
  before_save :copy_to_public
  has_one :soundkloud, :dependent => :destroy, :foreign_key=>"entry_id"
  
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
  def soundcloud_url
    self.soundkloud ? self.soundkloud.url : ""
  end
  def soundcloud_url=(url)
    if self.soundkloud 
      self.soundkloud.url = url
    else
      Soundkloud.create :url=>url, :entry_id=>self.id
    end
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
        elsif self.public_url
          self.public_url = nil
          client.delete(to)
        end
      rescue Exception => msg 
        if msg.kind_of? Dropbox::FileNotFoundError
          self.public_url = nil
          self.is_private = true
          self.errors[:base] << "Dropbox file not found: /#{self.branch}/#{self.dropbox_file}. You should delete this record." 
        end
        logger.debug "Error copy #{from} #{to} : #{msg}"
        # do nothing
      end
    end
  end
  def copy_to_soundcloud(soundcloud)
    return if !self.public_url
    client = Soundcloud.new(:access_token => SOUNDCLOUD.access_token)
    begin
      # :duration=>self.length ? self.length*1000 : nil,
      track = client.post('/tracks', :track=>{
        :title => soundcloud.title,
        :description=>soundcloud.description,
        :downloadable => true,
        :sharing=>'public',
        :track_type=>'bbg',
        :types=>"bbg",
        :label_name=>SOUNDCLOUD.upload_by,
        :genre=>soundcloud.genre,
        :tag_list=>self.dropbox_dir.sub("/",' '),
        :asset_data   => open(self.public_url)
      })
#      logger.debug "TRACK #{track.inspect}"
#      delete_from_soundcloud #delete old one first
      if track.id
        soundcloud.track_id = track.id
        soundcloud.url = track.permalink_url
        soundcloud.entry_id = self.id
        soundcloud.save
#        not working here
#        if !self.length || self.length < 1
#           track = client.get "/tracks/#{track.id}"
#           self.length = track.duration/1000
#           self.save
#        end
      end
      return soundcloud.url
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
      delete_from_soundcloud
    rescue Exception => msg
      logger.debug "#{msg}"
    end
  end
  def delete_from_soundcloud
    if self.soundkloud
      begin
        client = Soundcloud.new(:access_token => SOUNDCLOUD.access_token)
        client.delete "/tracks/#{self.soundkloud.track_id}"
      rescue Exception => msg
        logger.debug "ERROR: resolve #{self.soundkloud.url} #{msg}"
      end
    end
  end
  
  def dropbox_dir
     read_attribute(:dropbox_dir) || "bbg/#{self.branch}"
  end

  def branch=(value)
    write_attribute :branch, value.downcase
  end
  def self.sync_dropbox
    client = Entry.new.send "get_dropbox_session"
    self.all.each do | e |
      begin
        client.metadata e.file_path
      rescue
        # e.destroy
        puts "#{e.file_path} not in Dropbox, should be deleting"
      end
    end
  end
  
  def self.populate
    client = Entry.new.send "get_dropbox_session"
    client.list('bbg').each do |d|
      if d.is_dir
        # path="/bbg/Addis" 
        client.list(d.path).each do | s |
          self.add_entry(s)
        end  
      end
    end
  end
  def self.add_entry(s)
    if !s.is_dir
      arr = s.path.split('/')
      d_br = arr[2].to_s
      d_file = arr.last
      d_dir = arr[1..2].join('/')
      begin
        meta = client.metadata "Public/" + arr[2..3].join('/')
        meta = true if !!meta
      rescue
        meta = nil
      end
      e = Entry.find_by_dropbox_file d_file
      if !e
        Entry.create :branch=>d_br,
           :dropbox_file => d_file,
           :dropbox_dir=>d_dir,
           :mime_type=>s.mime_type,
           :phone_number=>'unknown',
           :is_private=>!meta
      else
        e.is_private = !meta
        e.branch = d_br 
        e.save
      end  
    end
  end
  
  def self.truncate
    connection.execute "truncate table #{table_name}"
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
    dropbox_session
  end
end
