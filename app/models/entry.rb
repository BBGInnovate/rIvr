require 'dropbox'
require 'open-uri'
require 'builder'

class Entry< ActiveRecord::Base
  before_save :add_properties
  after_destroy :delete_from_dropbox
  before_save :copy_to_public
  has_one :soundkloud, :foreign_key=>"entry_id"
  belongs_to :branch
  has_one :sorted_entry
  
  cattr_accessor :request_url
  
  HUMANIZED_COLUMNS = {:size=>"Size (bytes)"}

  def self.human_attribute_name(attribute, options = {})
    HUMANIZED_COLUMNS[attribute.to_sym] ||
    attribute.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
  end

  def dropbox_file_exists?
#    if self.forum_type=='bulletin'  
#      f = "#{DROPBOX.home}/bbg/#{self.branch.name}/#{self.forum_type}/#{self.dropbox_file}"
#    else
      f = "#{DROPBOX.home}#{self.branch.entry_files_folder}/#{self.dropbox_file}"
#      f2 = "#{DROPBOX.home}/bbg/#{self.branch.name.downcase}/#{self.dropbox_file}"
#    end
    return File.exists?(f) # || File.exists?(f2)
    
#    dir = "/system/#{self.branch.name.downcase}"
#    system_dir = "#{Rails.root}/public/#{dir}"
#    if !File.exists?("#{system_dir}")
#      FileUtils.mkdir_p "#{system_dir}"
#    end
#    url = "#{dir}/#{self.dropbox_file}"
#    system_path = "#{Rails.root}/public#{url}"
#    if !File.exists?("#{system_path}")
#      raw_content = dropbox_file_content
#      if !!raw_content
#        f = File.open("#{system_path}", 'wb') {|f| f.write(raw_content) }
#        url = "#{dir}/#{self.dropbox_file}"
#      else
#        url = nil
#      end
#    end
#    url
  end
  
  # return hash table key=branch_id, value=number of messages
  # hsh[:total] = sum of all messages
  # for all active branches
  def self.total_messages(start_date=nil, end_date=nil)
     Stat.total_messages(start_date, end_date)
  end
  
  def self.public_entries(caller)
    where("is_private=0 AND phone_number != #{caller}").order('id desc').limit(10).all
  end
  
  def file_path
    "/bbg/#{self.branch.name}/#{self.dropbox_file}"
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
  def to_dropbox_public
    # Public/#{self.branch} folder will be created if not exixts
    ds = DropboxSession.last
    if !!ds
      client = get_dropbox_session
      if self.forum_type=='bulletin'
        to = "Public/#{self.branch.name}/#{self.forum_type}/#{self.dropbox_file}"
        file_url = DROPBOX.public_dir + "/#{self.branch.name}/#{self.forum_type}/#{self.dropbox_file}"
      else
        to = "Public/#{self.branch.name}/#{self.dropbox_file}"
        file_url = DROPBOX.public_dir + "/#{self.branch.name}/#{self.dropbox_file}"
      end
      from = file_path
      begin
        self.public_url = file_url
        content = client.copy(from, to)
        self.is_private = 0
        return true
      rescue Exception => msg 
        if msg.kind_of? Dropbox::FileNotFoundError
          self.public_url = nil
          self.is_private = true
          self.errors[:base] << "Dropbox file not found: /#{self.branch.name}/#{self.dropbox_file}. You should delete this record." 
        end
        logger.debug "to_dropbox_public Error copy #{from} #{to} : #{msg}"
        return false
      end
    end
  end
  def to_soundcloud(soundcloud)
    # return if !self.public_url
    client = Soundcloud.new(:access_token => SOUNDCLOUD.access_token)
    begin
      # :duration=>self.length ? self.length*1000 : nil,
#      if !!self.public_url 
#        content = open(self.public_url)
#      else
        raw_content = dropbox_file_content
        f = File.open('/tmp/'+self.dropbox_file, 'wb') {|f| f.write(raw_content) }
        content_file = File.open('/tmp/'+self.dropbox_file, 'rb')
#      end
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
        :asset_data => content_file
      })
      content_file.close
      if track.id
        soundcloud.track_id = track.id
        soundcloud.url = track.permalink_url
        soundcloud.entry_id = self.id
        soundcloud.save
      end
      return soundcloud.url
    rescue
       logger.warn "Entry#to_soundcloud #{$!.message}"
       return "#{$!.message}"
    end
  end
  
  def copy_to_public
    # Public/#{self.branch} folder will be created if not exixts
    ds = DropboxSession.last
    if !!ds
      client = get_dropbox_session
      if self.forum_type=='bulletin'
        to = "Public/#{self.branch.name}/#{self.forum_type}/#{self.dropbox_file}"
        file_url = DROPBOX.public_dir + "/#{self.branch.name}/#{self.forum_type}/#{self.dropbox_file}"
      else
        to = "Public/#{self.branch.name}/#{self.dropbox_file}"
        file_url = DROPBOX.public_dir + "/#{self.branch.name}/#{self.dropbox_file}"
      end
      from = file_path
      begin
        if !self.is_private
          self.public_url = file_url
          # logger.debug "copy #{from} #{to}"
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
          self.errors[:base] << "Dropbox file not found: /#{self.branch.name}/#{self.dropbox_file}. You should delete this record." 
        end
        logger.debug "copy_to_public Error copy #{from} #{to} : #{msg}"
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
    self.dropbox_dir="bbg/#{self.branch.name}"
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
     read_attribute(:dropbox_dir) || "bbg/#{self.name}"
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
      branch = Branch.find_by_name d_br
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
        Entry.create :branch_id=>branch.id,
           :dropbox_file => d_file,
           :dropbox_dir=>d_dir,
           :mime_type=>s.mime_type,
           :phone_number=>'unknown',
           :is_private=>!meta
      else
        e.is_private = !meta
        e.branch_id = branch.id 
        e.save
      end  
    end
  end

  def self.truncate
    connection.execute "truncate table #{table_name}"
  end
  
  def self.upload_static_message(client, entry, branch)
    file_name = File.basename(entry.public_url)
    static_url = entry.public_url
    dropbox_file_url = "#{DROPBOX.public_dir}/#{branch.name}/#{file_name}"
    to = "Public/#{branch.name}/"
    if !Prompt.file_equal?(dropbox_file_url, static_url)
      puts "#{Time.now.utc} Uploading #{static_url} to #{to}/"
      client.upload open(static_url), to, :as=>file_name
      puts "#{Time.now.utc} Uploaded #{static_url} to #{to}/"
    else
       puts "#{to}#{file_name} unchanged"
    end
  end

  def self.parse_feed(url, limit=10)
    items = []
    added = 0
    megabyte = 1024*1024
    begin
      doc = Nokogiri::XML(open(url))
      doc.xpath('//item').each do |i|
      break if added >= limit

      enclosure =  i.xpath('enclosure')[0]
      length= enclosure[:length]
      if length
        length = length.to_f/megabyte
      end
      time_str = i.xpath('itunes:duration').text
      if !time_str.empty?
        time_arr = time_str.split(":")
        hr = time_arr[0].to_i
        mn = time_arr[1].to_i
        ss  = time_arr[2].to_i
        duration = hr*3600 + mn*60 + ss
      else
        duration = 0
      end
          
      if length < 5 && duration < 300
        entry = OpenStruct.new
        entry.public_url = enclosure[:url]
        items << entry
        added += 1
      end
    end
    rescue
      User.logger.warn "Entry parse_feed: #{$!}"
    end
    items
  end
  
  def checked?
     sorted_entry ? sorted_entry.checked? : false
  end
   
protected

  def dropbox_file_content
    ds = DropboxSession.last
    content = nil
    if !!ds
      dropbox_session = Dropbox::Session.new(DROPBOX.consumer_key, DROPBOX.consumer_secret)
      dropbox_session.set_access_token ds.token, ds.secret
      dropbox_session.mode = :dropbox
      # mime_type posted by IVR system may not be correct
      if self.forum_type=='bulletin'
        dir = "/bulletin"
      else
        dir = ''
      end
      begin
        meta = dropbox_session.metadata("bbg/#{self.branch.name}#{dir}/#{self.dropbox_file}")
        myentry = Entry.find_by_id self.id  # self is a readonly record
        myentry.mime_type = meta.mime_type
        myentry.size = meta.bytes
        myentry.save
        content = dropbox_session.download("bbg/#{self.branch.name}#{dir}/#{self.dropbox_file}")
      rescue
        puts "ERROR dropbox_file_content #{$!}"
      end
    else
      nil 
    end
    content
  end
end
