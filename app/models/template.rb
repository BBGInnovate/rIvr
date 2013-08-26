class Template < ActiveRecord::Base
  belongs_to :branch

  after_save :generate_forum_feed

  self.inheritance_column = "temp_type"
  #  has_attached_file :sound,
  #     :path => ":rails_root/public/system/:attachment/:id/:style/:filename",
  #     :url => "/system/:attachment/:id/:style/:filename"
  # name == 'introduction', 'message' etc.
  def self.find_me(branch_id, name)
    record = self.last :conditions=>["branch_id=? and name=?", branch_id, name]
    if !record
      self.create :branch_id=>branch_id, :name=>name
    else
      record
    end
  end

  def find_introduction
    self.class.where("branch_id=#{branch_id} AND name='introduction' AND is_active=1 AND identifier is not null").limit(1).order("created_at desc")
  end
    
  def generate_forum_feed
    branch.generate_forum_feed
  end

  # for forum prompts file
  def dropbox_dir
    "/bbg/#{self.branch.name.downcase}/#{self.class.name.downcase}"
    # "/Public/#{self.branch.name.downcase}/#{self.class.name.downcase}"
    # "/bbg/#{self.branch.name.downcase}/forum"
  end

  def upload_to_dropbox(file)
    # ext = file.original_filename.split(".")[1]
    client = self.get_dropbox_session
    if !!client
      to = self.dropbox_dir
      begin
        client.mkdir to
      rescue
        # do nothing
      end
      name = self.name
      begin
        re = client.upload(file.tempfile, to, :as=>file.original_filename)
        # path="/bbg/oddi/report/introduction.mp3"
        self.dropbox_file=re.path
        self.content_type=re.mime_type
        self.save!
      rescue Exception=>ex
        puts "Error #{ex.message}"
      end
    end
  end

  # name = 'introduction','message'
  def audio_link
    client = self.get_dropbox_session
    if !!client
      name = File.basename(self.dropbox_file)
      link = "system/#{self.branch.name.downcase}/#{self.class.name.downcase}"
      local="#{Rails.root}/public/#{link}"
      FileUtils.mkdir_p local
      local_file = "#{local}/#{name}"
      if !File.exists?(local_file)
        feed = client.download(self.dropbox_file)
        File.open(local_file, 'wb') {|f| f.write(feed) }
      end
      link = "#{link}/#{name}"
    else
      link = nil
    end
    link
  end

end
