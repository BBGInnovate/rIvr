class ModerationController < ApplicationController
  #  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  skip_before_filter :init
  #rails g kaminari:config
  
  # to deal with "HEAD true" request
  def dummy
    if request.head?
        head :created
    else
        Rails.logger.info "Derp #{request.method}"
    end
  end
  
  def index
    @controller = request.filtered_parameters['controller']
    p = params[:page] || 1
    @entries = Entry.joins(:branch).where("branches.is_active=1").
    order("id desc").page(p).per(10)
    
    @results = @entries
  end

  def search
    search_for = params[:search_for]
    start_date = params[:start_date]
    end_date = params[:end_date]
    forum_type = params[:forum_type]
    branch = params[:branch]
    location = params[:location]
     
    p = params[:page] || 1
      
    @entries_query = Entry.includes([:branch=>:country]).where("branches.is_active=1")

    if !!start_date && !!end_date
      conditions["entries.created_at"] = start_date..end_date
      @entries_query = @entries_query.where("entries.created_at"=>start_date..end_date)
    end
    if !!forum_type
      conditions["entries.forum_type in (?)", forum_type]
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
         where("entries.is_private=1").page(p).per(10)
    when 'published'
      @results = @entries_query.
         where("entries.is_private=0").page(p).per(10)
    when 'deleted'
      @results = @entries_query.
         where("entries.is_active=0").page(p)
    end
#    headers["Content-Type"] = 'text/javascript'
#    render :partial=>'paginate', :layout=>false, :content_type => 'text/javascript'
    render :partial=>'search_results', :layout=>false, :content_type => 'text'
  end
end