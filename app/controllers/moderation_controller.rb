class ModerationController < ApplicationController
  #  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]

  #rails g kaminari:config
  layout 'moderation'
  # to deal with "HEAD true" request
  def dummy
    if request.head?
        head :created
    else
        Rails.logger.info "Derp #{request.method}"
    end
  end

  def index
    uri = request.env['REQUEST_URI']
    uri.slice!(request.path)
    Entry.request_url = uri
    session['entries.created_at'] = 'desc'
    p = params[:page] || 1
#    # this is for listen content
#    @entries = Entry.joins(:branch).where("branches.is_active=1").
#    where(:is_active=>true).
#    order("id desc").page(p).per(10)
#    # this is for syndicated content
#    @syndicated = Entry.joins(:branch).where("branches.is_active=1").
#        joins(:soundkloud).
#        order("id desc").page(p).per(10)
        
    # this is for initial search_results content corresponding to Incoming radio
    # button is checked
    start_date = Branch.message_time_span.days.ago.to_s(:db)
    end_date = Time.now.to_s(:db)
    
    # not get for Report type where forum_session_id == 0
    @sorted = SortedEntry.where("rank>0 AND forum_session_id>0").
        where("created_at"=>start_date..end_date)
    
    @results = Entry.where("entries.is_private=1 AND entries.is_active=1").
       joins(:branch).where("branches.is_active=1").
       where("forum_session_id > 0 ").
       where("entries.created_at"=>start_date..end_date)
    #   order("entries.id desc").page(p)
       
    if (params[:branch_id])
      @results = @results.where(["entries.branch_id = ?", params[:branch_id]])
    end
    @results = @results.order("entries.id desc") #.page(p)

    sorted_ids = @sorted.map{|s| s.entry_id}
    @results = @sorted + @results.map{|r| r if !sorted_ids.include?(r.id) }.compact
    unless @results.kind_of?(Array)
      @results = @results.page(p)
    else
      @results = Kaminari.paginate_array(@results).page(p)
    end

    if params[:ajax]
      # request from paginate links in listen, syndicate  page
      render :partial=>params[:partial], :layout=>false, :content_type=>'text' and return
    else
      # normal index request
    end
  end

  def edit
    if params[:cancel]
      redirect_to "/moderation" and return
    end
    
    id = params[:id]
    @entry = Entry.find_by_id id
    
    if (params[:syndicate].to_i == 1) || params[:soundcloud]
      upload_soundlcloud
      render :action=>'soundcloud', :layout=>false, :content_type=>'text' and return
    elsif (params[:playlist].to_i == 1)
      render :action=>'soundcloud_playlist', :layout=>false, :content_type=>'text' and return
    elsif (params[:akamai].to_i == 1)
      if ftp_akamai
        txt="{\"error\":\"success\",\"message\":\"Uploaded to Akamai\"}"
      else
        txt="{\"error\":\"error\",\"message\":\"#{@entry.errors.full_messages.first}\"}"
      end
      render :text=>txt,:layout=>false, :content_type=>'text' and return
    elsif params[:publish].to_i == 1
      if publish_dropbox
        @entry.save
        txt="{\"error\":\"success\",\"message\":\"Published to Dropbox\"}"
      else
        txt="{\"error\":\"error\",\"message\":\"#{@entry.errors.full_messages.first}\"}"
      end
      render :text=>txt,:layout=>false, :content_type=>'text' and return
    elsif params[:delete].to_i == 1
      @entry.is_active = 0
      @entry.save!
      txt="{\"error\":\"notice\",\"message\":\"Message deleted\"}"
      render :text=>txt,:layout=>false, :content_type=>'text' and return
    elsif params[:undelete].to_i == 1
      @entry.is_active = 1
      @entry.save!
      txt="{\"error\":\"notice\",\"message\":\"Message undeleted\"}"
      render :text=>txt,:layout=>false, :content_type=>'text' and return 
    else
      txt="{\"error\":\"error\",\"message\":\"Not know what to do \"}"
      render :text=>txt,:layout=>false, :content_type=>'text' and return
    end
  end
  
  def ftp_akamai
    @entry.ftp_akamai
  end
  
  def publish_dropbox
    @entry.to_dropbox_public
  end
  
  def upload_soundlcloud
    if @entry.soundkloud
       @soundcloud = @entry.soundkloud
    else
       @soundcloud = Soundkloud.new
    end
    @result = nil
    s = params[:soundcloud]
    if s
       @soundcloud.title = s[:title]
       @soundcloud.genre = s[:genre]
       @soundcloud.description=s[:description]
       if @soundcloud.valid?
         @result = @entry.to_soundcloud @soundcloud
       else
         @result = @soundcloud.errors.full_messages
       end
      puts "A upload_soundlcloud #{@result}"
    end
  end
  
  def search
    search_for = params[:search_for] || 'incoming'
    start_date = params[:start_date]
    end_date = params[:end_date]
    forum_type = params[:forum_type]
    branch = params[:branch]
    if branch.kind_of?(String)
       branch = [branch]
    end
    location = params[:location]
     
    p = params[:page] || 1
      
    # not get for Report type where forum_session_id == 0
    @sorted = SortedEntry.where("rank>0 AND forum_session_id > 0 ").all
    @entries_query = Entry.includes([:branch=>:country]).
      where("branches.is_active=1").
      where("forum_session_id > 0 ").
      order(order_by)

    if !!start_date && !!end_date
      @entries_query = @entries_query.where("entries.created_at"=>start_date..end_date)
    end
    
    # is forum_title now
    if !!forum_type && forum_type.first.to_i != 0
      # @entries_query = @entries_query.where(["entries.forum_type in (?)", forum_type])
      @entries_query = @entries_query.where(["entries.forum_session_id in (?)", forum_type])
    end
    # if forum title is selected then branch selection is ignored
    
    if !!branch
       @sorted = []
       if !forum_type
         # get for Report type when branch is specified
         if branch.first.to_i != 0
           @entries_query = @entries_query.where(["branches.id in (?) ", branch])
           branches = Branch.where(["id in (?) ", branch])
         else
           branches = Branch.where(:is_active=>true)
         end
         branches.all.each do |b|
           @sorted << SortedEntry.get(b.id, b.active_forum_session.id)
         end
         @sorted.flatten!
       end
    end
    if !!location
      @entries_query = @entries_query.where(["countries.name like ? ", location])
    end   
    
    case search_for
    when 'incoming'
      @results = @entries_query.
         where("entries.is_private=1").page(p)
    when 'published'
      @results = @entries_query.
         where("entries.is_private=0").page(p)
    when 'syndicated'
      @results = @entries_query.joins(:soundkloud).page(p)
    when 'deleted'
      @results = @entries_query.
         where("entries.is_active=0").page(p)
    end
#    unless @sorted.kind_of?(Array)
#      @sorted = @sorted.page(p)
#    else
#      @sorted = Kaminari.paginate_array(@sorted).page(p)
#    end
    sorted_ids = @sorted.map{|s| s.entry_id}
    @results = @sorted + @results.map{|r| r if !sorted_ids.include?(r.id) }.compact
    unless @results.kind_of?(Array)
      @results = @results.page(p)
    else
      @results = Kaminari.paginate_array(@results).page(p)
    end
    
#    headers["Content-Type"] = 'text/javascript'
#    render :partial=>'paginate', :layout=>false, :content_type => 'text/javascript'
    render :partial=>'search_results', :layout=>false, :content_type => 'text'
  end
  
  def order_by
     o = params[:order] || "entries.id"
     a = ['asc','desc']
     if !session[o]
       session[o] = 'desc'
     else
       a.delete session[o]
       session[o] = a.first
     end
     "#{o} #{session[o]}"
  end
  
  def branch
    
  end
  
  def forums
     id = params[:id].to_i
     if id != 0
       branches=[Branch.find_by_id(id)]
     else
       branches=Branch.where(:is_active=>true)
     end
     options = []
     branches.each do |branch|
       options = options | branch.voting_sessions.order("created_at desc").map{|b| [b.name,b.id]}
     end
     opt = view_context.options_for_select(options, id)
     render :text=>opt, :layout=>false
  end
end
