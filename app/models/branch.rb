require 'builder'
require 'open-uri'

class Branch< ActiveRecord::Base
  self.table_name = "branches"
  attr_accessor :vote_result
  
  belongs_to :country, :foreign_key=>"country_id"
  has_many :voting_sessions do
    def latest
      last
    end
  end
  has_many :events
  has_many :healths
  has_many :reports do
    def latest
      res = select("max(id) as id").group(:name).where(:is_active=>true)
      select("id, name, dropbox_file, voting_session_id").where(["id in (?)", res.map{|t| t.id}])
    end
  end
  has_many :bulletins do
    def latest
      res = select("max(id) as id").group(:name).where(:is_active=>true)
      select("id, name, dropbox_file, voting_session_id").where(["id in (?)", res.map{|t| t.id}])
    end
  end

  # is a vote template
  has_many :votes do
    def latest
      res = select("max(id) as id").group(:name).where(:is_active=>true)
      select("id, name, dropbox_file, voting_session_id").where(["id in (?)", res.map{|t| t.id}])
    end

    def original_identifier
      coll = latest
      intro = coll.select{|t| t.name=='introduction'}
      if intro.size == 0
        return nil
      end
      identifier = intro.last.voting_session.name
    end

    def candidate_result
      coll = latest
      intro = coll.select{|t| t.name=='introduction'}
      if intro.size == 0
        return nil
      end
      identifier = intro.last.voting_session_id
      candidate = coll.select{|t| (t.name=='candidate_result')}
      if candidate.size == 0
        return nil
      end
      if (candidate.voting_session_id==identifier)
        candidate.last
      else
        nil
      end
    end

    # if candidate_result prompt was uploaded indicating poll has ended
    def ended
      !!candidate_result
    end
  end

  # vote or poll results
  # pattern= 1, 0, -1
  has_many :vote_results  do
    def get_result(pattern, voting_session_id=nil)
      i = voting_session_id || (!!last && last.voting_session_id)
      if i
         where(:result=>pattern, :voting_session_id=>i)
      else
         []
      end
    end 
    def yes(voting_session_id=nil)
      #      brch = proxy_association.owner
      get_result(1)
    end

    def no(voting_session_id=nil)
      get_result(-1)
    end

    def none(voting_session_id=nil)
      get_result(0)
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
        begin
          records = client.list("Public/#{brch.name}/#{forum}")
          records.each do |record|
            if !record.is_dir
              entry = OpenStruct.new
              entry.public_url = record.path
              entries << entry
            end
          end
        rescue

        end
        entries
      else # from static_rss
        entries = Entry.parse_feed(opt.feed_url, limit)
      end
    end
  end

  def identifier
    if self.forum_type=="vote"
      self.votes.original_identifier
    else
      "Not Defined"
    end
  end
  #  def forum_type
  #    read_attribute(:forum_type) || false
  #  end

  def forum_prompts
    begin
      records = self.send(self.forum_type.pluralize)
      records.latest
    rescue
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
    tmp = "#{DROPBOX.tmp_dir}/#{self.name}"
    # tmp = "#{DROPBOX.tmp_dir}"
    FileUtils.mkdir_p tmp
    if ::Rails.env != 'development'
      system("sudo chmod -R 777 #{tmp}")
    end
    file_path = "#{tmp}/forum.xml"
    File.open(file_path, "w") do |file|
      xml = ::Builder::XmlMarkup.new(:target => file, :indent => 2)
      xml.instruct! :xml, :version => "1.0"
      xml.rss :version => "2.0" do
        xml.channel do
          xml.created_at Time.now.getutc
          xml.forum_type self.forum_type
          xml.identifier self.identifier
          xml.status (self.forum_type=="vote" && self.votes.ended) ? "vote ended" : "OK"
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