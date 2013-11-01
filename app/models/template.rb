class Template < ActiveRecord::Base
  belongs_to :branch
  belongs_to :voting_session
#  after_save :generate_forum_feed

  self.inheritance_column = "temp_type"
  #  has_attached_file :sound,
  #     :path => ":rails_root/public/system/:attachment/:id/:style/:filename",
  #     :url => "/system/:attachment/:id/:style/:filename"
  # name == 'introduction', 'message' etc.
  def self.find_me(branch_id, name)
    record = where(["branch_id=? and name=?", branch_id, name]).last
    if !record
      record = self.create :branch_id=>branch_id, :name=>name
    else
      record
    end
    record
  end

  def find_introduction
    self.class.where("branch_id=#{branch_id} AND name='introduction' AND is_active=1 AND voting_session_id is not null").limit(1).order("created_at desc")
  end
    
  def generate_forum_feed
    if self.is_active==true
      branch.generate_forum_feed_xml  # let cron job do the work
    end
  end

  # for retrieve forum prompt files
  def dropbox_dir
    ss = dropbox_file.split "/"
    ss[0..(ss.size-2)].join("/")
    ss
  end

  def upload_to_dropbox(file, identifier=nil)
    # ext = file.original_filename.split(".")[1]
    to = self.branch.prompt_files_folder(identifier)
    remote_dir = DROPBOX.home+to
    remote_file = remote_dir+"/#{file.original_filename}"
    
    # not use local dropbox
    if 1==0 && (Dir.exists? DROPBOX.home)
      # dropbox client is installed
      # have to be sure the dropbox client is running
      if !Dir.exists?(remote_dir)
         FileUtils.mkdir_p remote_dir
      end
      FileUtils.copy file.tempfile.path, remote_file
      self.content_type=file.content_type
      self.dropbox_file=to+"/"+ file.original_filename
      self.save!
      logger.info "Copied #{file.tempfile.path} to #{remote_file}"
    else    
      client = self.get_dropbox_session
      if !!client
        begin
          client.mkdir to
        rescue
          logger.warn "Error: upload_to_dropbox : #{$!}"
        end
        begin
          re = client.upload(file.tempfile, to, :as=>file.original_filename)
          # path="/bbg/oddi/report/introduction.mp3"
          self.dropbox_file=re.path
          self.content_type=re.mime_type
          self.save!
          logger.warn "INFO: Dropbox uploaded: #{file.original_filename}"
        rescue Exception=>ex
          logger.warn "Error #{ex.message}"
        end
      end
    end
  end

  def save_recording_to_dropbox(data, filename)
      client = self.get_dropbox_session
      if !!client
        to = self.branch.prompt_files_folder
        begin
          client.mkdir to
        rescue
          logger.warn "Error: upload_to_dropbox : #{$!}"
        end
        begin
          re = client.upload(data, to, :as=>filename)
          # path="/bbg/oddi/report/introduction.mp3"
          self.dropbox_file=re.path
          self.content_type=re.mime_type
          self.save!
          logger.warn "INFO: Dropbox uploaded: #{filename}"
        rescue Exception=>ex
          logger.warn "Error #{ex.message}"
        end
      end
    end
  # name = 'introduction','message'
  def audio_link
    link = nil
    client = self.get_dropbox_session
    if !!client && self.dropbox_file && self.voting_session
      name = File.basename(self.dropbox_file)
      forum_title = self.voting_session.friendly_name
      link = "system/#{self.branch.friendly_name}/#{self.class.name.downcase}/#{forum_title}"
      local="#{Rails.root}/public/#{link}"
      FileUtils.mkdir_p local
      local_file = "#{local}/#{name}"
      begin
        if !File.exists?(local_file)
          feed = client.download(self.dropbox_file)
          File.open(local_file, 'wb') {|f| f.write(feed) }
        end
        link = "#{link}/#{name}"
      rescue
      end
    end
    link
  end

  def identifier
    !!voting_session ? voting_session.id : nil
  end
  
  def name_map(name)
    name.titleize
  end
  
  def self.truncate
     connection.execute "truncate table #{table_name}"
  end
    
end
