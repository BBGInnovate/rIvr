class ModerationController < ApplicationController
  #  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]

  #rails g kaminari:config
  def index
    p = params[:page] || 1
    @entries = Entry.joins(:branch).where("branches.is_active=1").
    order("id desc").page(p)
  end

  def search
    search_for = params[:search_for]
    date = params[:date]
    started = Date.parse(date).beginning_of_day.to_s(:db)
    ended = Date.parse(date).end_of_day.to_s(:db)
    
    branch = params[:branch]
    location = params[:location]
    conditions = ""
    if date.size > 0
      conditions << "events.created_at between '#{started}' AND '#{ended}'"
      
    end
    
    case search_for
    when 'incoming'
      @entries = Entry.includes(:country).where(:is_active=>true).
      where("countries.name like '%#{term}%'").all
    when 'published'
      @entries = Entry.includes(:country).where(:is_active=>true).
      where("branches.name like '%#{term}%'").all
    when 'deleted'
      @enries = Entry.includes(:country).where(:is_active=>true).
      where("branches.status like '%#{term}%'").all
    end
    render :partial=>'search_results', :layout=>false, :content_type=>'text'

  end
end