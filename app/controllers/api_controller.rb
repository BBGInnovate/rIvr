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
    @session_id = !!entry ? entry.delete(:session_id) : nil
    event = params[:event]
    create_entry entry if entry
    create_event event if event
    render :nothing=>true
  end

  def message
    params[:message] = {:branch=>'oddi'} if !params[:message]
    feed = params[:message]
    if feed
       branch = feed[:branch].downcase
       @messages = Prompt.where("branch='#{branch}' AND is_active=1").all
       respond_to do |format|
         format.rss { render :layout => false } # message.rss.builder
       end
    end
  end
  
  def feed
    params[:feed] = {:branch=>'oddi', :caller_id=>'1234'} if !params[:feed]
    feed = params[:feed]
    if feed
      branch = feed[:branch].downcase
      caller_id = feed[:caller_id]
      options = Configure.conf(branch)
      feed_limit = options.feed_limit
     
      if options.feed_source == 'dropbox'
         @entries = Entry.where("branch='#{branch}' AND is_private=0 AND (phone_number is null OR phone_number!='#{caller_id}')").all(:select => "public_url", :order => "id DESC", :limit => feed_limit )
         if @entries.size == 0
            @entries = parse_feed(options.feed_url, feed_limit)
         end
      else
        @entries = parse_feed(options.feed_url, feed_limit)
      end
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
    doc = Nokogiri::XML(open(url))
    entries = []
    @links = doc.xpath('//item/enclosure/@url')[0..(limit-1)].each do |i|
       entry = OpenStruct.new
       entry.public_url = i.text
       entries << entry
    end
    entries
  end
  
  def create_entry(attr)
    e = Entry.find_by_dropbox_file attr[:dropbox_file]
    if e
      e.updated_at = Time.now
      e.update_attributes attr
    else
      e=Entry.create attr
      if !!@session_id
        # create an even as well
        Event.create :branch=>e.branch.downcase,:caller_id=>e.phone_number,
          :identifier=>e.dropbox_file, :page_id=>Page.recordMessage,
          :action_id=>Action.save_recording,
          :session_id=>@session_id
      end  
    end
  end

  def create_event(attr)
    attr[:branch] = attr[:branch].downcase
    Event.create attr
  end
end