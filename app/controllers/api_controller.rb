require 'ostruct' 
require 'open-uri'
require 'nokogiri'

class ApiController < ApplicationController
  skip_filter :authorize
#  doorkeeper_for :all
  def index
    # create event via http get
    event = params[:event]
    create_event event if event
    respond_to do |format|
      format.rss { render :layout => false } # index.rss.builder
    end
  end
  def create
    entry = params[:entry]
    event = params[:event]
    vote_result = params[:vote_result]
    if entry
      @session_id = entry.delete(:session_id)
      create_entry entry
    elsif event
      create_event event
    elsif vote_result
      create_vote_result vote_result
    end
    render :nothing=>true
  end

  # for voice prompts
  def message
    params[:feed] = {:branch=>'oddi'} if !params[:feed]
    feed = params[:feed]
    if feed
       branch = Branch.find_by_name feed[:branch]
       @messages = Prompt.where("branch_id='#{branch.id}' AND is_active=1").all
       respond_to do |format|
         format.rss { render :layout => false } # message.rss.builder
       end
    end
  end
  
  # for listening 
  def feed
    params[:feed] = {:branch=>'oddi', :caller_id=>'1234'} if !params[:feed]
    feed = params[:feed]
    if feed
      branch = Branch.find_by_name feed[:branch]
      caller_id = feed[:caller_id]
      options = Configure.conf(branch)
      feed_limit = options.feed_limit
     
      if options.feed_source == 'dropbox'
        # since each IVR solution has http://localhost/Uploads service
        # provide the audio file locally
        # @entries = Entry.where("branch='#{branch}' AND is_private=0 AND (phone_number is null OR phone_number!='#{caller_id}')").all(:select => 'CONCAT("http://localhost/Uploads/", dropbox_file) AS public_url', :order => "id DESC", :limit => feed_limit )
        # @entries = Entry.where("branch='#{branch}' AND is_private=0 AND (phone_number is null OR phone_number!='#{caller_id}')").all(:select => "public_url", :order => "id DESC", :limit => feed_limit )
        @entries = Entry.where("branch_id='#{branch.id}' AND is_private=0").all(:select => "public_url", :order => "id DESC", :limit => feed_limit )              
         if @entries.size == 0
            @entries = parse_feed(options.feed_url, feed_limit)
         end
      else
         @entries = parse_feed(options.feed_url, feed_limit)
      end
      # @entries = @entries.select{|e| url_available?(e.public_url) }
      respond_to do |format|
        format.rss { render :layout => false } # feed.rss.builder
      end
    end
  end

  def prompt
    name = params[:msg][:name]
    res = Message.where("name='#{name}'").select("description").all
    if res.size>0
       render :text=>res[0].description, :content_type=>'text'
    else
      render :text=>'', :content_type=>'text'
    end
  end
  protected

  def parse_feed(url, limit=10)
    # url = "http://www.lavoixdelamerique.com/podcast/"
    entries = []
    begin
      doc = Nokogiri::XML(open(url))
      @links = doc.xpath('//item/enclosure/@url')[0..(limit-1)].each do |i|
         entry = OpenStruct.new
         entry.public_url = i.text
         entries << entry
      end
    rescue
      logger.warn "parse_feed: #{$!}"
    end
    entries
  end
  
  def create_entry(attr)
    branch = Branch.find_by_name attr.delete(:branch)
    if branch.forum_type=='bulletin'
      page_id = Page.recordBulletin
    elsif branch.forum_type=='vote'
      page_id = Page.recordComment
    else
      page_id = Page.recordMessage
    end
    attr[:branch_id] = branch.id
      e = Entry.create attr
      if !!@session_id
        # create an even as well
        Event.create :branch_id=>branch.id,:caller_id=>e.phone_number,
            :identifier=>e.dropbox_file, :page_id=>page_id,
            :action_id=>Action.save_recording,
            :created_at => e.created_at,
            :session_id=>@session_id
      end
  end

  def create_vote_result(attr)
    branch = Branch.find_by_name attr.delete(:branch)
    attr[:branch_id] = branch.id
    if attr[:caller_id] =~ /System/
      VoteResult.delete_all "branch_id='#{branch.id}' AND caller_id = 'System'"
    end
    logger.warn "VOTE ATTR #{attr.inspect}"
    # branch_id, identifier, vote_result, caller_id, session_id vote (1,0,-1)
    attr.delete(:identifier) # TODO use this to get voting_session_id ?
    attr[:voting_session_id]=branch.voting_sessions.latest.id
    
    VoteResult.create(attr)
  end
  
  def create_event(attr)
    branch = Branch.find_by_name attr.delete(:branch)
    attr[:branch_id] = branch.id
    if attr[:caller_id] =~ /System/
      Event.delete_all "branch_id='#{branch.id}' AND caller_id = 'System'"
    end
    Event.create(attr)
  end
end
