require 'dropbox'
require 'open-uri'
require 'builder'

class Entry< ActiveRecord::Base
  before_save :add_properties
  after_destroy :delete_from_dropbox
  before_save :copy_to_public
  has_one :soundkloud, :foreign_key=>"entry_id"
  
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
          self.delete_from_soundcloud
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
        self.soundkloud.destroy
      rescue Exception => msg
        logger.debug "ERROR: delete_from_soundcloud #{self.soundkloud.url} #{msg}"
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
  
#  # public messages for IVR caller to listen
#  def self.rss_feeds
#    client = self.new.get_dropbox_session
#    Entry.select("distinct branch").each do | en |
#      branch = en.branch.downcase
#      options = Configure.conf(branch)
#      feed_limit = options.feed_limit
#     
#      if options.feed_source == 'dropbox'
#         entries = Entry.where("branch='#{branch}' AND is_private=0").all(:select => "public_url", :order => "id DESC", :limit => feed_limit )              
#         if entries.size == 0
#            entries = parse_feed(options.feed_url, feed_limit)
#         end
#      else
#         entries = parse_feed(options.feed_url, feed_limit)
#      end
#      
#      if entries.size > 0
#        local_file_path = self.rss_feed(entries, branch)
#        FileUtils.mkdir_p File.dirname(local_file_path)
#        new_content = File.open(local_file_path, "r").read
#        remote_dropbox_file = "#{DROPBOX.public_dir}/#{branch}/#{File.basename(local_file_path)}"
#      
#        begin
#          # check if branch messages.xml is uploaded to dropbox
#          old_xml = open(remote_dropbox_file)
#          old_content = old_xml.read
#        rescue Exception => e
#          old_content = (e.message =~ /404/) ? "" : nil
#        end
#        if (old_content == "") || (new_content != old_content)
#           puts "Upload #{local_file_path} to Public/#{branch}/"
#           client.upload local_file_path, "Public/#{branch}/" 
#
#           # upload static_rss type public messages to dropbox
#           entries.each do |entry|
#             # this entry is not Entry type!
#             upload_static_message(client, entry, branch)
#           end
#        else
#           puts "rss_feeds : #{File.basename(local_file_path)} is in Public/#{branch}/"
#        end
#      end
#    end
#  end
#  
#  def self.rss_feed(entries, branch)
#    file_path = "#{DROPBOX.tmp_dir}/#{branch}/messages.xml"
#    File.open(file_path, "w") do |file|
#      xml = ::Builder::XmlMarkup.new(:target => file, :indent => 2)
#      xml.instruct! :xml, :version => "1.0" 
#      xml.rss :version => "2.0" do
#        xml.channel do
#          xml.branch branch
#          xml.count entries.size
#          for entry in entries
#            xml.item do
#              xml.link entry.public_url.gsub("https","http")
#            end
#          end
#       end
#     end
#   end
#   return file_path
# end
  
  def self.truncate
    connection.execute "truncate table #{table_name}"
  end
  
  def self.upload_static_message(client, entry, branch)
    file_name = File.basename(entry.public_url)
    static_url = entry.public_url
    dropbox_file_url = "#{DROPBOX.public_dir}/#{branch}/#{file_name}"
    to = "Public/#{branch}/"
    if !Prompt.file_equal?(dropbox_file_url, static_url)
      puts "#{Time.now.utc} Uploading #{static_url} to #{to}/"
      client.upload open(static_url), to, :as=>file_name
      puts "#{Time.now.utc} Uploaded #{static_url} to #{to}/"
    else
       puts "#{to}#{file_name} unchanged"
    end
  end

  def self.parse_feed(url, limit=10)
    entries = []
    begin
      doc = Nokogiri::XML(open(url))
      doc.xpath('//item/enclosure/@url')[0..(limit-1)].each do |i|
         entry = OpenStruct.new
         entry.public_url = i.text
         entries << entry
      end
    rescue
      logger.warn "Entry parse_feed: #{$!}"
    end
    entries
  end
  
protected
#  def get_dropbox_session
#    ds = DropboxSession.last
#    if !!ds
#      dropbox_session = Dropbox::Session.new(DROPBOX.consumer_key, DROPBOX.consumer_secret)
#      dropbox_session.set_access_token ds.token, ds.secret
#      dropbox_session.mode = :dropbox
#    else
#      nil
#    end
#    dropbox_session
#  end
end
