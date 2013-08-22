require 'builder'
require 'open-uri'

class Branch< ActiveRecord::Base
  self.table_name = "branches"
  belongs_to :country, :foreign_key=>"country_id"
  has_many :events
  has_many :healths
  has_many :reports do 
    def latest
      res = select("max(id) as id").group(:name).where(:is_active=>true)
      select("id, name, dropbox_file").where(["id in (?)", res.map{|t| t.id}])
    end
  end
  has_many :bulletins do 
    def latest
      res = select("max(id) as id").group(:name).where(:is_active=>true)
      select("id, name, dropbox_file").where(["id in (?)", res.map{|t| t.id}])
  end
  end
  has_many :prompts, :conditions =>"is_active=1"

  validates_presence_of :name 
  validates :name, :uniqueness => {:scope => :country_id}
    
  has_many :options do
    def feed_limit
      where(:name=>'feed_limit').last
    end
    def feed_source
      where(:name=>'feed_source').last
    end
    def feed_url
      where(:name=>'feed_url').last
    end
  end
  has_many :entries do
    # allow from dropbox or static rss, depending on configuration
    def forum_messages(limit=10)
      brch = proxy_association.owner
      opt = Configure.conf(brch)
      forum = brch.forum_type
      limit = [limit, opt.feed_limit].max
      # if forum !='bulletin'
        conditions="entries.forum_type='#{forum}'"
      # end
      if opt.feed_source == 'dropbox'
#        if forum == 'report'
          # upload report forum messages to "/Public/oddi/#{forum}/"
          entries = []
          client = brch.get_dropbox_session
          records = client.list("Public/#{brch.name}/#{forum}")
          records.each do |record|
            if !record.is_dir
              entry = OpenStruct.new
              entry.public_url = record.path
              entries << entry
            end
          end
          entries
#        else
          # forum type == bulletin. IVR client posts caller 
          # message to Dashboard with xml:
          # xml.entry do
          #  xml.forum_type 'bulletin'
          #  xml.branch brch
#          where("public_url is not null").all :conditions=>conditions,
#          :select => "public_url", :order => "id DESC",
#          :limit => limit
#        end
      else # from static_rss
        entries = Entry.parse_feed(opt.feed_url, limit)
      end
    end
  end
  
#  def forum_type
#    read_attribute(:forum_type) || false
#  end
  
  def forum_prompts
    # if undefined forum_type ,return reports
    if self.forum_type == 'report'
      self.reports.latest
    elsif self.forum_type == 'bulletin'
      self.bulletins.latest
    else
      []
    end
  end
  
  # generate forum.xml in dropbox public/<branch>
  def generate_forum_feed(client=nil)
    local_file = self.forum_feed
    remote_file = "#{DROPBOX.public_dir}/#{self.name}/#{File.basename(local_file)}"
    to = "Public/#{self.name}/"
    if !Prompt.file_equal?(remote_file, local_file)
       begin
         if !client
           client = get_dropbox_session
         end
         client.upload local_file, to
         puts "Uploaded #{local_file} to #{to}"
       rescue Exception=>e
         puts "Error generate_xml client.upload(#{local_file}, #{to}) #{e.message}"
       end
     else
       puts "#{to}#{File.basename(local_file)} unchanged"
     end
  end
  
  # for old voice forum voice prompts
  def generate_prompts_feed(client=nil)
    # In Branch, Prompt tables Branch is not downcased
    local_file = self.prompts_feed
    remote_file = "#{DROPBOX.public_dir}/#{name}/#{File.basename(local_file)}"
    to = "Public/#{name}/"
    if !Prompt.file_equal?(remote_file, local_file)
      if !client
        client = get_dropbox_session
      end
      client.upload local_file, to
      puts "Uploaded #{local_file} to #{to}"
    else
      puts "#{to}#{File.basename(local_file)} unchanged"
    end
  end
  
  def self.constant_iter(&block)
      Action.all.each do |c|
        yield c.name, c.id
      end
    end
  
    self.constant_iter do |name, id|
      begin
        class_eval "def self.#{name.gsub(' ','_')}; #{id}; end"
      rescue
        logger.error "#{name} - #{id} cannot converted"
      end
    end
  def self.find_me(attr)
    self.first :conditions=>["id=? or name=?", attr, attr]
  end
  
  def forum_feed(limit=10)
    # get public messages
    entries = self.entries.forum_messages(limit)
    # get custom voice prompts
    # forum_type must be 'report' or 'bulletin'
    # call branch.reports() or branch.bulletins()
    prompts = self.forum_prompts
    # tmp = "#{DROPBOX.tmp_dir}/#{self.name}"
    tmp = "#{DROPBOX.tmp_dir}"
    FileUtils.mkdir_p tmp
    file_path = "#{tmp}/forum.xml"
    File.open(file_path, "w") do |file|
      xml = ::Builder::XmlMarkup.new(:target => file, :indent => 2)
      xml.instruct! :xml, :version => "1.0"
      xml.rss :version => "2.0" do
        xml.channel do
          xml.forum_type self.forum_type
          xml.branch self.name
          xml.count entries.size
          for m in prompts
            xml.prompt do
              # <introduction>/bbg/tripoli/bulletin/introduction.wav</introduction>
              xml.method_missing(m.name, m.dropbox_file)
            end
          end
          for m in entries
            # these dropbox_file is to copy to ../Uploads in client
            xml.item do
              xml.link m.public_url.gsub("https","http")
            end
          end
        end
      end
    end
    return file_path
  end
  
  def prompts_feed
    records = self.prompts
    tmp = "#{DROPBOX.tmp_dir}/#{self.name}"
    FileUtils.mkdir_p tmp
    file_path = "#{tmp}/prompts.xml"
    File.open(file_path, "w") do |file|
      xml = ::Builder::XmlMarkup.new(:target => file, :indent => 2)
      xml.instruct! :xml, :version => "1.0"
      xml.rss :version => "2.0" do
        xml.channel do
          xml.forum_type self.forum_type
          xml.branch self.name
          xml.count records.size
          for m in records
            xml.item do
              xml.method_missing(m.name, m.url)
            end
          end
        end
      end
    end
    return file_path
  end
  protected
end