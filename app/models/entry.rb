require 'dropbox'
require 'open-uri'
require 'builder'
require 'net/ftp'
class Entry< ActiveRecord::Base
  @@ftp = nil
  
  # alias_attribute :forum_session, :voting_session
   
  before_create :add_properties
  before_save :remove_properties
  
  # before_save :copy_to_public
  
  has_one :soundkloud, :foreign_key=>"entry_id"
  belongs_to :branch
  has_one :sorted_entry
  belongs_to :voting_session, :foreign_key=>"forum_session_id"
  cattr_accessor :request_url
  
  HUMANIZED_COLUMNS = {:size=>"Size (bytes)"}

  def self.human_attribute_name(attribute, options = {})
    HUMANIZED_COLUMNS[attribute.to_sym] ||
    attribute.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
  end

  def dropbox_file_exists?
    filename = "#{self.dropbox_dir}/#{self.dropbox_file}"
    f = "#{DROPBOX.home}#{filename}"
    res = File.exists?(f)
    if !res
      client = self.get_dropbox_session
      begin
        res = client.metadata filename
      rescue
        res = false
      end
    end
    return res
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
    "#{self.dropbox_dir}/#{self.dropbox_file}"
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
  
  def forum_session
    s = OpenStruct.new
    s.name = 'None'
    s.friendly_name = 'None'
    s.id = nil
    voting_session || s
  end
  
  def to_dropbox_public
    # Public/#{self.branch} folder will be created if not exixts
    ds = DropboxSession.last
    if !!ds
      client = get_dropbox_session
      to = "Public#{self.dropbox_dir}/#{self.dropbox_file}"
      file_url = DROPBOX.public_dir + "#{self.dropbox_dir}/#{self.dropbox_file}"
      from = self.dropbox_dir
      begin
        self.public_url = file_url
        content = client.copy(from, to)
        self.is_private = 0
        return true
      rescue Exception => msg 
        if msg.kind_of? Dropbox::FileNotFoundError
          self.public_url = nil
          self.is_private = true
          self.errors[:base] << "Dropbox file not found: #{self.dropbox_dir}/#{self.dropbox_file}. You should delete this record." 
        end
        logger.debug "to_dropbox_public Error copy #{from} #{to} : #{msg}"
        return false
      end
    end
  end
  
  def to_soundcloud(soundcloud)
    # return if !self.public_url
    client = Soundcloud.new(:access_token => (self.branch.soundcloud_access_token || SOUNDCLOUD.access_token))
    begin
      raw_content = dropbox_file_content
      f = File.open('/tmp/'+self.dropbox_file, 'wb') {|f| f.write(raw_content) }
      content_file = File.open('/tmp/'+self.dropbox_file, 'rb')
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
        playlist = nil
        client.get('/me/playlists').each do |p|
          if (p.title == self.forum_session.name)
            playlist = p
            break
          end 
        end
        if !playlist
          # create a playlist and add tracks to 
          playlist = client.post('/playlists', :playlist => {
            :title => self.forum_session.name,
            :sharing => 'public',
            :tracks => [{:id=>track.id}]
          })
        else
          # add tracks to playlist
          # has_track = false
          # playlist.tracks.each do |t|
          #  if t.id == track.id
          #    has_track = true
          #    break
          #  end
          # end
          playlist = client.put(playlist.uri, :playlist => {
              :tracks => playlist.tracks << {:id=>track.id}
          })
        end
        soundcloud.playlist_id = playlist.id
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
  
  # deplicated
  def Xcopy_to_public
    ds = DropboxSession.last
    if !!ds
      client = get_dropbox_session
      to = "Public#{self.dropbox_dir}/#{self.dropbox_file}"
      file_url = DROPBOX.public_dir + "#{self.dropbox_dir}/#{self.dropbox_file}"
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
          self.errors[:base] << "Dropbox file not found: /#{self.dropbox_dir}/#{self.dropbox_file}. You should delete this record." 
        end
        logger.debug "copy_to_public Error copy #{from} #{to} : #{msg}"
        # do nothing
      end
    end
  end
  
  def add_properties
    # this only used when create entry from client api call
    self.dropbox_dir= self.branch.entry_files_folder if !self.dropbox_dir
  end
  
  def remove_properties
    if !self.is_active
      delete_from_dropbox
      delete_from_soundcloud
      delete_from_ftp
      if self.sorted_entry
        self.sorted_entry.rank = 0
        self.sorted_entry.save
      end
    end
  end
  
  # only delete public entry
  def delete_from_dropbox
    s = get_dropbox_session
    begin
      self.update_attributes :public_url=>nil,:is_private=>true
      to = "Public#{self.dropbox_dir}/#{self.dropbox_file}"
      s.delete(to)
    rescue Exception => msg
      logger.info "#{msg}"
    end
  end
  def delete_from_soundcloud
    if self.soundkloud
      begin
        client = Soundcloud.new(:access_token => (self.branch.soundcloud_access_token || SOUNDCLOUD.access_token))
        client.delete "/tracks/#{self.soundkloud.track_id}"
        self.soundkloud.destroy
      rescue Exception => msg
        logger.info "ERROR: delete_from_soundcloud #{self.soundkloud.url} #{msg}"
      end
    end
  end
  def delete_from_ftp
    if self.ftp_url
      uri = URI.parse e.ftp_url
      tmp=uri.path.split("/")
      dir = tmp[0..(tmp.size-2)].join("/")
      ftp = ftp_connect
      begin
        root = (self.branch.ftp_path || FTP.path).split('/').first
        ftp.chdir "/#{root}"+dir
        ftp.delete "/#{root}"+uri.path
        self.update_attribute ftp_url,nil
      rescue Exception => msg
        logger.info "#{msg}"
      end
    end
  end
  
  def dropbox_dir
    dir = "/bbg/#{self.branch.friendly_name}/#{self.forum_type}/#{self.forum_session.friendly_name}/entries"
    dir2 = read_attribute(:dropbox_dir)
    if dir != dir2
      # self may be a readonly 
      my = Entry.find_by_id self.id
      my.update_attribute(:dropbox_dir, dir) if my
    end
    dir
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
    dropbox_file_url = "#{DROPBOX.public_dir}/#{branch.friendly_name}/#{file_name}"
    to = "Public/#{branch.friendly_name}/"
    if !Prompt.file_equal?(dropbox_file_url, static_url)
      puts "#{Time.now.utc} Uploading #{static_url} to #{to}/"
      client.upload open(static_url), to, :as=>file_name
      puts "#{Time.now.utc} Uploaded #{static_url} to #{to}/"
    else
       puts "#{to}#{file_name} unchanged"
    end
  end

  # for feed based limit to 1
  def self.parse_feed(url, limit=1)
    items = []
    added = 0
    length = nil
    duration = nil
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
        
      end
          
      if (!!length || !!duration) && length < 5 && duration < 300
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
  
  def ftp_connect
    user = self.branch.ftp_user || FTP.user
    pass = self.branch.ftp_pwd || FTP.pwd
    server = self.branch.ftp_server || FTP.server
    @@ftp = Net::FTP.new(server, user, pass) if !@@ftp
    @@ftp
  end
  
  def ftp_akamai
    localfile = DROPBOX.home + dropbox_dir + "/#{dropbox_file}"
    if !File.exists?(localfile)
       logger.error "NOT EXISTS ! #{localfile}"
       return false
    end
    ftp_path = self.branch.ftp_path || FTP.path
    folders = [ftp_path, self.branch.friendly_name, 
      self.forum_type,
      self.forum_session.friendly_name,
      self.created_at.strftime("%Y"),
      self.created_at.strftime("%m")]
    ftp = ftp_connect
    
    remote = folders.join("/")
    folders.each{ |folder|
      begin
        ftp.chdir(folder)
      rescue Net::FTPPermError, NameError => boom # it doesn't exist
        ftp.mkdir(folder) 
        ftp.chdir(folder) 
        puts "pwd #{ftp.pwd}" 
      end
    }
    begin
       ftp.putbinaryfile(localfile, dropbox_file)
       self.ftp_url = "#{self.branch.ftp_url_base || FTP.url_base}" +
          "#{self.forum_type}/#{self.branch.friendly_name}/#{self.forum_session.friendly_name}/" + 
          "#{self.created_at.strftime('%Y')}/#{self.created_at.strftime('%m')}/" +
          dropbox_file
       self.save
    rescue Net::FTPPermError, NameError => boom # it doesn't exist
       puts "#{$!}"
       return false
    end
    ftp.close
    return self.ftp_url
  end
  
  def audio_link
    link = nil
    if self.dropbox_file && self.voting_session
      name = File.basename(self.dropbox_file)
      forum_title = self.voting_session.friendly_name
      link = "/system/#{self.branch.friendly_name}/#{self.class.name.downcase}/#{forum_title}"
      local="#{Rails.root}/public/#{link}"
      FileUtils.mkdir_p local
      local_file = "#{local}/#{name}"
      begin
        if !File.exists?(local_file)
          client = Branch.dropbox_session
          feed = client.download("#{self.dropbox_dir}/#{self.dropbox_file}")
          File.open(local_file, 'wb') {|f| f.write(feed) }
        end
        link = "#{link}/#{name}"
      rescue
        logger.info "DROPBOX download #{$!}"
        self.destroy
      end
    end
    link
  end
  
protected

  def dropbox_file_content
    ds = DropboxSession.last
    content = nil
    if !!ds
      dropbox_session = Dropbox::Session.new(DROPBOX.consumer_key, DROPBOX.consumer_secret)
      dropbox_session.set_access_token ds.token, ds.secret
      dropbox_session.mode = :dropbox
      begin
        meta = dropbox_session.metadata("#{self.dropbox_dir}/#{self.dropbox_file}")
        myentry = Entry.find_by_id self.id  # self is a readonly record
        myentry.mime_type = meta.mime_type
        myentry.size = meta.bytes
        myentry.save
        content = dropbox_session.download("#{self.dropbox_dir}/#{self.dropbox_file}")
      rescue
        puts "ERROR dropbox_file_content #{$!}"
      end
    else
      nil 
    end
    content
  end
end
