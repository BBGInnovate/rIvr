class ModerationController < ApplicationController
  #  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  before_filter :init
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
  # override application#init
  def init
    @controller = request.filtered_parameters['controller']
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
    @results = Entry.where("entries.is_private=1 AND entries.is_active=1").
       joins(:branch).where("branches.is_active=1").
       where("entries.created_at"=>start_date..end_date)
    #   order("entries.id desc").page(p)
       
    if (params[:branch_id])
      @results = @results.where(["entries.branch_id = ?", params[:branch_id]])
    end
    @results = @results.order("entries.id desc").page(p)
    
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
    location = params[:location]
     
    p = params[:page] || 1
      
    @entries_query = Entry.includes([:branch=>:country]).
      where("branches.is_active=1").
      order(order_by)

    if !!start_date && !!end_date
      @entries_query = @entries_query.where("entries.created_at"=>start_date..end_date)
    end
    if !!forum_type
      @entries_query = @entries_query.where(["entries.forum_type in (?)", forum_type])
    end
    if !!branch
       @entries_query = @entries_query.where(["branches.name like ? ", branch])
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
            @results = @entries_query.joins(:soundkloud).
            page(p)
    when 'deleted'
      @results = @entries_query.
         where("entries.is_active=0").page(p)
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
end