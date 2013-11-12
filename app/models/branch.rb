require 'builder'
require 'open-uri'

class Branch< ActiveRecord::Base
  acts_as_gmappable :process_geocoding => true
  
  before_save :update_friendly_name
  
  self.table_name = "branches"
  attr_accessor :vote_result, :test

  has_one :health
  has_many :branch_feeds
  belongs_to :country, :foreign_key=>"country_id"
#  include HealthHelper

  def update_friendly_name
    self.friendly_name=self.name.parameterize
  end
  
  def last_activity
    events.where(["action_id != ?", Action.ping_server]).last.created_at.to_s(:db) rescue 'N/A'
  end
  def gmaps4rails_infowindow
    htm = "<span class=\"my-tooltip\"><b>#{self.name.titleize}</b> <br/>"
    htm << "<b>#{self.country.name}</b></span><br/>"
    htm << "<span class=\"my-tooltip\">Last Activity: #{last_activity} </span><br/>"
    htm << "<span class=\"my-tooltip\">IVR #: #{self.ivr_call_number} </span><br/>"
    htm << "<span class=\"my-tooltip\">POC:  #{self.contact}</span><br/>"
    htm << "<span class=\"my-tooltip\">Health: #{health_image}</span> <br/>"
    htm.html_safe
  end
  def title_infowindow
      htm = "<span class=\"my-tooltip\"><b>#{self.name.titleize}</b> <br/>"
      htm << "<span class=\"my-tooltip\">Last Activity: #{last_activity} </span><br/>"
      htm << "<span class=\"my-tooltip\">IVR #: #{self.ivr_call_number} </span><br/>"
      htm << "<span class=\"my-tooltip\">POC:  #{self.contact}</span><br/>"
      htm
  end
        
  def gmaps4rails_title
     self.name
  end
  
  def gmaps4rails_address
    self.name
  end
  
  def country_flag_url
    f = read_attribute(:country_flag_url)
    if !f || f.empty?
      '/assets/rails.png'
    else
      f
    end
  end
    
  def message_time_span
    # if not defined return 7 days
     read_attribute(:message_time_span) || 7
  end
    
  def self.message_time_span
     o = Option.where("name='message_time_span' AND (branch_id is NULL OR branch_id = 0)").first
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
  
  
  # folder where to upload voice prompts files
  def prompt_files_folder(session_name=nil)
    if !session_name
      session_name = active_forum_session.name
    end
    folder = "/bbg/#{self.friendly_name}/#{self.forum_type}/#{session_name.parameterize}"  
    folder += "/prompts"
  end
  # folder where to upload callers' messages
  def entry_files_folder(session_name=nil)
    if !session_name
      session_name = active_forum_session.name
    end
    folder = "/bbg/#{self.friendly_name}/#{self.forum_type}/#{session_name.parameterize}"
    folder += "/entries"
  end
    
  def self.top_activity
    Event.joins(:branch).where("branches.is_active=1").
      select("branch_id, max(events.created_at) as created_at").
      group(:branch_id).order("events.created_at desc").limit(3)
  end
  
  def self.forum_types
    ['report','bulletin','vote']
  end
  
  def self.forum_type_ui(forum_type)
      case forum_type
      when 'vote'
        'Vote or Poll (Engage)'
      when 'bulletin'
        'Ask the community (Connect)'
      when 'report'
        'News Report (inform)'
      else
        ''
      end
  end
  def forum_type_ui
      case self.forum_type
      when 'vote'
        'Vote or Poll (Engage)'
      when 'bulletin'
        'Ask the community (Connect)'
      when 'report'
        'News Report (inform)'
      else
        ''
      end
  end
  
#  has_and_belongs_to_many :users
  # for array sort_by so that not health items come first
  # order by 0,1
  def health?
    return 0 if (!self.health || !self.health.last_event)
    if self.health.last_event.to_i > self.health.no_activity.hours.ago.to_i
      1
    else
      0
    end
  end
    
  def unhealth?
    return true if (!self.health || !self.health.last_event)
    self.health.last_event.to_i < self.health.no_activity.hours.ago.to_i
  end
  def health_image
    if unhealth?
      %{<img class="red-light" width="15" height="15" src="/assets/red.png" />}
    else
      %{<img src="/assets/images/icon-analytics.png" width="23" height="21" alt="radio signal" />}
    end  
  end
  def gmap_marker
    if unhealth?
      "/assets/red.png"
    else
      "/assets/radio-wave.png"
    end  
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
#  has_many :healths
  
  # for report prompts
  has_many :reports do
    def current()
      res = select("max(id) as id").group(:name).where("name!='headline'").
          where(:voting_session_id=>proxy_association.owner.current_forum_session.id)
      select("id, name, branch_id, dropbox_file, voting_session_id").where(["id in (?)", res.map{|t| t.id}])
    end
    def latest(active=true)
      res = select("max(id) as id").group(:name).where(:is_active=>active).where("name!='headline'").
          where(:voting_session_id=>proxy_association.owner.active_forum_session.id)
      select("id, name, branch_id, dropbox_file, voting_session_id").where(["id in (?)", res.map{|t| t.id}])
    end
    def headline()
      item = where(:name=>'headline' ).
        where(:voting_session_id=>proxy_association.owner.current_forum_session.id).last
      if !item
        item = Report.create :name=>'headline', 
              :branch_id=>proxy_association.owner.id,
              :voting_session_id=>proxy_association.owner.current_forum_session.id
          
      end
      item
    end
  end
  # for bulletin prompts
  has_many :bulletins do
    def current()
      res = select("max(id) as id").group(:name).
            where(:voting_session_id=>proxy_association.owner.current_forum_session.id)
      select("id, name, branch_id, dropbox_file, voting_session_id").where(["id in (?)", res.map{|t| t.id}])
    end
    def latest(active=true)
      res = select("max(id) as id").group(:name).where(:is_active=>active).
            where(:voting_session_id=>proxy_association.owner.active_forum_session.id)
      select("id, name, branch_id,dropbox_file, voting_session_id").where(["id in (?)", res.map{|t| t.id}])
    end
    
  end

  # is a vote template
  # for vote prompts
  has_many :votes do
    def current()
      res = select("max(id) as id").group(:name).
            where(:voting_session_id=>proxy_association.owner.current_forum_session.id)
      all_items = select("id, name, branch_id,dropbox_file, voting_session_id, description").where(["id in (?)", res.map{|t| t.id}])
      items = all_items.select{|i| i.description != 'result'}
            
      vote_result_items = all_items.select{|i| i.description == 'result'}
      if vote_result_items.size == 3
        vote_result_items
      else
        items
      end
      items + vote_result_items 
    end
    def latest(active=true)
      res = select("max(id) as id").group(:name).where(:is_active=>active).
            where(:voting_session_id=>proxy_association.owner.active_forum_session.id)
      all_items = select("id, name, branch_id, dropbox_file, voting_session_id, description").where(["id in (?)", res.map{|t| t.id}])
      items = all_items.select{|i| i.description != 'result'}
            
      vote_result_items = all_items.select{|i| i.description == 'result'}
      if vote_result_items.size == 3
        vote_result_items
      else
        items
      end
    end

    def result_templates
      res = select("max(id) as id").group(:name).where("description='result'")
         where(:voting_session_id=>proxy_association.owner.active_forum_session.id)
      items = select("id, name, branch_id, dropbox_file, voting_session_id, description").where(["id in (?)", res.map{|t| t.id}])
      
    end
    
    def Acandidate_result
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
      if latest.size > 0
        latest.last.description == 'result'
      else
        false
      end
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

    def stats(voting_session_id=nil)
      i = voting_session_id || proxy_association.owner.active_forum_session.id
      if i
       items = where(:voting_session_id=>i)
      else
       items = nil
      end
      stat = {:total=>0, :yes=>0,:no=>0,:none=>0,
           :yes_per=>0,:no_per=>0,:none_per=>0
         }
      if items
         yes = items.select {|a| a.result==1}.size
         no = items.select {|a| a.result==-1}.size
         none = items.select {|a| a.result==0}.size
         total = yes+no+none
         if total > 0 
           stat = {:total=>total, :yes=>yes,:no=>no,:none=>none,
             :yes_per=>yes*100/total,:no_per=>no*100/total,:none_per=>none*100/total
           }
         end
      end
      stat
    end
    
    # block to be removed
    def get_result(pattern, voting_session_id=nil)
      i = voting_session_id || proxy_association.owner.active_forum_session.id
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
    # block to be removed
  end
  # files in this table are replaced by 
  # Branch#prompts_files_folder
  # has_many :prompts, :conditions =>"is_active=1"

  validates_presence_of :name
  validates :name, :uniqueness => {:scope => :country_id}

  # replace options table
  def my_feed
    if !!self.test
      forum = self.current_forum_session
    else
      forum = self.active_forum_session
    end
    branch_feeds.find_or_create_by_forum_session_id(forum.id)
  end
  def feed_limit
      my_feed.feed_limit || 3
      # return 10 if self.new_record?
      # opt = Option.where(:branch_id=>self.id, :name=>'feed_limit').last
      # !!opt ? opt.value : nil
  end
  def feed_source
      my_feed.feed_source      
      # return nil if self.new_record?
      # opt = Option.where(:branch_id=>self.id, :name=>'feed_source').last
      # !!opt ? opt.value : nil
  end
  def feed_url
      my_feed.feed_url
      # return nil if self.new_record?
      # opt = Option.where(:branch_id=>self.id, :name=>'feed_url').last
      # !!opt ? opt.value : nil
     
  end
  def feed_limit=(val)
     my_feed.update_attribute :feed_limit,val
  end
  def feed_source=(val)
     my_feed.update_attribute :feed_source,val
  end
  def feed_url=(val)
     my_feed.update_attribute :feed_url,val
  end
  
  def Xfeed_limit=(val)
      opt = Option.where(:branch_id=>self.id, :name=>'feed_limit').last
      if opt
        opt.value = val
        opt.save
      else
        Option.create :branch_id=>self.id, :name=>'feed_limit', :value=>val
      end
  end
  def Xfeed_source=(val)
      opt = Option.where(:branch_id=>self.id, :name=>'feed_source').last
      if opt
        opt.value = val
        opt.save
      else
        Option.create :branch_id=>self.id, :name=>'feed_source', :value=>val
      end
  end
  def Xfeed_url=(val)
      opt = Option.where(:branch_id=>self.id, :name=>'feed_url').last
      if opt
        opt.value = val
        opt.save
      else
        Option.create :branch_id=>self.id, :name=>'feed_url', :value=>val
      end
  end
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
  has_many :sorted_entries
  has_many :entries do
    def incomings(limit=20)
      id = proxy_association.owner.id
      fs_id = proxy_association.owner.active_forum_session.id
      sorted = SortedEntry.get(id, fs_id).map{|a|a.entry_id}
      if sorted.size == 0
         sorted = 0
      end
      limit = proxy_association.owner.feed_limit if !limit
      items = where(:forum_session_id=>proxy_association.owner.active_forum_session.id).
           where("id not in (?)", sorted).
           order("id desc").limit(limit)
    end
    
    def published_to_be_deleted(limit)
      items = where(:is_privite=>false).
         where(:forum_type=>proxy_association.owner.forum_type)
      if proxy_association.owner.forum_type=='report'
         
      else
         items = items.where(:forum_session_id=>proxy_association.owner.active_forum_session.id)
      end 
      items.order("id desc").limit(limit)
    end
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
    self.first :conditions=>["id=? or name=? or friendly_name=?", attr, attr, attr]
  end

  def current_forum_session
    s = self.voting_sessions.last
    self.voting_sessions.find_by_current(true) || s
  end
  
  def active_forum_session
    s = OpenStruct.new
    s.name = 'None'
    s.friendly_name = s.name.parameterize
    s.id = nil
    s = self.voting_sessions.where(:is_active=>true).last || s
    s
  end
  def identifier(identifier=nil)
    if !!identifier
      identifier.parameterize
    else
      self.active_forum_session.friendly_name
    end
  end
  
  # replace def forum_feed
  def forum_feed_xml
    # get public messages
    items = self.listen_messages
    prompts = self.forum_prompts
    
    forum= !!self.test ? current_forum_session : active_forum_session
    
    tmp = "#{DROPBOX.tmp_dir}/#{self.friendly_name}"
    FileUtils.mkdir_p tmp
    if ::Rails.env != 'development'
      system("sudo chmod -R 777 #{tmp}")
    end
    file_path = "#{tmp}/forum_feed.xml"
    File.open(file_path, "w") do |file|
      xml = ::Builder::XmlMarkup.new(:target => file, :indent => 2)
      xml.instruct! :xml, :version => "1.0"
      xml.rss :version => "2.0" do
        xml.channel do
          # xml.created_at Time.now.getutc
          xml.forum_type self.forum_type
          xml.forum_session forum.friendly_name
          xml.entry_upload_folder self.entry_files_folder(forum.friendly_name)
          xml.prompt_upload_folder self.prompt_files_folder(forum.friendly_name)
          xml.status (self.forum_type=="vote" && self.votes.ended) ? "vote ended" : "OK"
          xml.branch self.friendly_name
          xml.count items.size
          for m in prompts
            xml.prompt do
              # <introduction>/bbg/tripoli/vote/October 9//introduction.wav</introduction>
              xml.method_missing(m.name, m.dropbox_file)
            end
          end
          for m in items
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
  
  def test_forum_feed_xml(client=nil)
     self.test = true
     self.forum_feed_xml
     self.test = false
  end
  
  # generate forum.xml in dropbox public/<branch>
  def generate_forum_feed_xml(client=nil)
    if !client
      client = get_dropbox_session
    end
    forum= !!self.test ? current_forum_session : active_forum_session
    local_file = self.forum_feed_xml
    dropbox_branch = "#{DROPBOX.home}/bbg/#{self.friendly_name}"
    remote_file = "#{dropbox_branch}/#{File.basename(local_file)}"
    remote_forum_file = "#{dropbox_branch}/#{self.forum_type}/#{forum.friendly_name}/#{File.basename(local_file)}"
    if !Branch.xml_equal?(remote_forum_file, local_file)    
      begin
        to = "bbg/#{self.friendly_name}/#{forum.friendly_name}"
        client.upload local_file, to
        logger.info "Uploaded #{local_file} to #{to}"
      rescue Exception=>e
        logger.info "Error generate_xml client.upload(#{local_file}, #{to}) #{e.message}"
      end
    end
    if !Branch.xml_equal?(remote_file, local_file)
      # add delete_old_files node
      builder = Nokogiri::XML::Builder.new do
        delete_old_files 1
      end
      doc = Nokogiri::XML(IO.read(local_file))
      node = doc.xpath('//channel').first
      node.add_child builder.doc.root
      file = File.open(local_file,'w')
      file.puts doc.to_xml
      file.close
      # not use dropbox client.
      if (1==0) && Dir.exists?(DROPBOX.home)
        # dropbox client is installed
        if !Dir.exists?(dropbox_branch)
          FileUtils.mkdir_p dropbox_branch
        end
        FileUtils.copy local_file, remote_file
        logger.info "Copied #{local_file} to #{remote_file}"
      elsif !self.test
        begin
          to = "bbg/#{self.friendly_name}/"
          client.upload local_file, to
          logger.info "Uploaded #{local_file} to #{to}"
        rescue Exception=>e
          logger.info "Error generate_xml client.upload(#{local_file}, #{to}) #{e.message}"
        end
      end
    else
      logger.info "#{to}#{File.basename(local_file)} unchanged"
      # FileUtils.copy local_file, remote_file
      # puts "Copied #{local_file} to #{remote_file}"
    end
  end
  def listen_messages()
    logger.info "AAAA !!self.test #{!!self.test} self.feed_source=#{self.feed_source}"
    if !!self.test
      forum = self.current_forum_session
    else
      forum = self.active_forum_session
    end
    limit = self.feed_limit
    items = []
    arr = []
    if self.forum_type=='report'
      if self.feed_source == 'static_rss'
        items = Entry.parse_feed(self.feed_url, limit)
      else
        # get the last entry for now
        arr = [SortedEntry.where(:branch_id=>self.id, 
          :forum_session_id=>forum.id).last].compact
        arr.each do |f|
          if !!self.test || f.entry.is_active
            item = OpenStruct.new
            item.public_url = f.dropbox_dir + "/"+f.dropbox_file
            items << item
          end
        end
      end
    elsif self.forum_type=='vote' || self.forum_type=='bulletin'
      vs = forum
      arr = SortedEntry.get(self.id, vs.id)
      arr.each do |f|
        if (f.entry.dropbox_file_exists?)
          item = OpenStruct.new
          item.public_url = f.dropbox_dir + "/" + f.dropbox_file
          items << item
        else
          puts "Not exists! #{f.dropbox_dir}/#{f.dropbox_file}"
        end
      end
    end
    items
  end
  
  def self.xml_equal?(old_file, new_file)
    # remove delete_old_files node before compare
    new_content = ""
    old_content = File.exists?(old_file) ? File.open(old_file).read : "A"
    begin
      doc = Nokogiri::XML(IO.read(new_file))
      doc.search('//delete_old_files').remove
      new_content = doc.to_xml
    rescue Exception=>e
      puts "INFO : file_equal?(#{new_file}) : #{e.message}"
    end
    (new_content.gsub!(" ","") == old_content.gsub!(" ",""))
  end
  
  def forum_prompts()
    begin
      records = self.send(self.forum_type.pluralize)
      if !!self.test
         records.current
      else
         records.latest
      end
    rescue
      []
    end
  end
  
  # find audio files for Report forum and insert to SortedEntries table
  # TODO add to cron?
  def insert_report_files
     Dir["#{DROPBOX.home}#{entry_files_folder}/*"].each_with_index do |f, i|
       bname = File.basename(f)
       se = SortedEntry.where(:branch_id=>self.id, 
          :dropbox_file=>bname, :forum_session_id=>nil).last
       if !se 
         e = Entry.create :branch_id=>self.id, :dropbox_file=>bname,
                :forum_type=>'report', :dropbox_dir=>entry_files_folder,
                :is_private=>false
         SortedEntry.create :branch_id=>self.id, :entry_id=>e.id,
                            :dropbox_file=>bname, :rank=>i+1
       else
         se.update_attribute :rank, i+1
       end
     end
  end
  
  # @reboot $HOME/.dropbox-dist/dropboxd
  # @reboot mkdir /mnt/dropbox; mkdir -p /mnt/rails/log; mkdir -p /mnt/rails/system; chmod -R 777 /mnt/
  # */5 * * * * /bin/bash -l -c 'cd /data/ivr/current && 
  # /usr/local/bin/bundle exec rails runner -e staging  "Branch.create_audio_files"'  > /tmp/dashboard-cron.log 2>&1


  def self.create_audio_files
    Branch.where(:is_active=>true).each do |b|
      b.entries.each do |t|
        t.audio_link
      end
      
      Template.where(:branch_id=>b.id).each do |t|
        t.audio_link
      end
    end
  end
  
  def clean_prompt_files
  # TODO clean outdated files
  
  end
  protected
end