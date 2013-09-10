require 'builder'
require 'open-uri'

class Branch< ActiveRecord::Base
  acts_as_gmappable :process_geocoding => true
  self.table_name = "branches"
  attr_accessor :vote_result

  has_one :health
#  include HealthHelper
  
  def gmaps4rails_infowindow
    htm = "<span class=\"my-tooltip\"><b>#{self.name.titleize}</b> <br/>"
    htm << "<b>#{self.country.name}</b></span><br/>"
    htm << "<span class=\"my-tooltip\">Last Activity: #{entries.last.created_at.to_s(:db) rescue 'N/A'} </span><br/>"
    htm << "<span class=\"my-tooltip\">IVR #: #{self.ivr_call_number} </span><br/>"
    htm << "<span class=\"my-tooltip\">POC:  #{self.contact}</span><br/>"
    htm << "<span class=\"my-tooltip\">Health: #{health_image}</span> <br/>"
    htm.html_safe
  end
      
  def gmaps4rails_title
     self.name
  end
  
  
  def message_time_span
    # if not defined return 7 days
     read_attribute(:message_time_span) || 7
  end
    
  def self.message_time_span
     o = Option.where(:name=>'message_time_span', :branch_id=>0).first
     if o
       o.value.to_i
     else
       7
     end
  end
    
  def contact
    read_attribute(:contact) ||  'undefined'
  end
  def ivr_call_number
    read_attribute(:ivr_call_number) || 'undefined'
  end
  
  def self.top_activity
    Event.select("branch_id, max(created_at) as created_at").
      group(:branch_id).order("created_at desc").limit(3)
  end
#  has_and_belongs_to_many :users
  
  belongs_to :country, :foreign_key=>"country_id"
  
  def unhealth?
    return true if !self.health
    self.health.last_event < self.health.no_activity.hours.ago
  end
  def health_image
    if unhealth?
      img = '/assets/red.png'
      klass  = "red-light"
    else
      img = '/assets/green.png'
      klass = "green-light"
    end  
    img_tag = %{<img class="#{klass}" width="15" height="15" src="#{img}" />}
  end
  
  has_many :alerted_messages 
  
  has_many :voting_sessions do
    def latest
      last
    end
  end
  has_many :events do
    def get_length(session_rows)
      listen_started = nil
      listen_ended = nil
      session_listen_time = 0
      session_rows.each do |row|
        if row.action_id == 3 && !listen_started
          listen_started = row.created_at
        elsif row.action_id == 4 && !!listen_started && !listen_ended
          if row.created_at > listen_started
            listen_ended = row.created_at
          end
        end
        if !!listen_ended
          session_listen_time += (listen_ended.to_i - listen_started.to_i)
          listen_ended = nil
          listen_started = nil
        end
      end
      session_listen_time
    end
    # listened[:total] == total listening in seconds
    # listened[:average] == ave listening in seconds
    # listened[:number_of_calls] == number of calls for listening
    def listened(start_date=nil, end_date=nil)
      start_date = 1.month.ago.to_s(:db) if !start_date
      end_date = Time.now.to_s(:db) if !end_date
      my_events = where(:created_at=>start_date..end_date).
         where("action_id in (#{Action.begin_listen},#{Action.end_listen})").
         select("session_id, branch_id, created_at").all
           
      sessions = my_events.group_by{|e| e.session_id}
      total_seconds = 0
      session_number = sessions.keys.size
      sessions.keys.each do |session_d|
        session_rows=sessions[session_id].value
        total_seconds += get_length(session_rows)
      end
      ave = total_seconds / sessions.keys.size
      hsh={:total=>total_seconds, 
           :number_of_calls=>sessions.keys.size,
           :average=>ave}
    end
    ## return total listening time in second for the time interval
    def listened_length(start_date=nil, end_date=nil)
      # start_date, end_date must be format Time.now.to_s(:db)
      start_date = 1.month.ago.to_s(:db) if !start_date
      end_date = Time.now.to_s(:db) if !end_date
      my_events = where(:created_at=>start_date..end_date).
        where("action_id in (#{Action.begin_listen},#{Action.end_listen})").
          select("session_id, branch_id, created_at").all
     
      sessions = my_events.group_by{|e| e.session_id}
      total_seconds = 0
      session_number = sessions.keys.size
      sessions.keys.each do |session_d|
        session_rows=sessions[session_id].value
        total_seconds += get_length(session_rows)
      end
      total_seconds
      # AppliactionHelper#format_seconds(total_seconds)
    end
  end
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
    def by_session
      sessions = select("distinct voting_session_id")
      rows = all
      sessions.each do |s|
        
      end
    end
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
    # return number of recorded messages in seconds
    def total_message_length(start_date=nil, end_date=nil)
      start_date = 1.month.ago.to_s(:db) if !start_date
      end_date = Time.now.to_s(:db) if !end_date
      total_seconds = where(:created_at=>start_date..end_date).
         select("cast(sum(length) AS SIGNED) AS total").last.total.to_i
      
      # AppliactionHelper#format_seconds(total_seconds)
    end

    # return number of total caller recorded messages for this branch
    def total_messages(start_date=nil, end_date=nil)
      start_date = 1.month.ago.to_s(:db) if !start_date
      end_date = Time.now.to_s(:db) if !end_date
      numbers = where(:created_at=>start_date..end_date).
        select("count(entries.id) AS total").last.total
    end
        
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

  # in seconds
  def self.recorded(start_date=nil, end_date=nil)
    start_date = 1.month.ago.to_s(:db) if !start_date
    end_date = Time.now.to_s(:db) if !end_date
    Entry.where(:created_at=>start_date..end_date).select("branch_id, cast(sum(length) AS SIGNED) AS total").
       group(:branch_id)
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