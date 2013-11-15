class HealthcheckController < ApplicationController
#  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
    
  layout 'application'
  
  def index
    if !@branches 
      @branches = Branch.includes(:country).
      where(:is_active=>true).all
    end
    Health.populate(@branches)
    @branches.sort_by!{|a| a.health?} 
    if params[:branch_id]
      @branches = @branches.select{|b| b.unhealth? && (b.id == params[:branch_id].to_i)} 
    end
    if params[:alarm].to_i == 1
       @branches = @branches.select{|a| a if a.health.send_alarm }
    end
    
    @map_width = '100%' 
    @map_height = '250px'
  end
  
  def edit
    @record = Health.find_by_branch_id params[:id]
    record = params[:record]
    if record
      @record.attributes = record
      if @record.valid?
        @record.save
        txt = "{\"error\":\"success\", \"msg\":\"Record updated\"}"
        render :text=>txt,:layout=>false, :content_type=>'text'
      else
        msg = @record.errors.full_messages.first
        txt = "{\"error\":\"error\", \"msg\":\"#{msg}\"}"
      end
    else
      render :layout=>false, :content_type=>'text'
    end
  end
  
  def search
    search_for = params[:search_for]
    term = params[:term].downcase
    case search_for
    when 'country'
      @branches = Branch.includes(:country).where(:is_active=>true).
        where("countries.name like '%#{term}%'").all
    when 'name'
      @branches = Branch.includes(:country).where(:is_active=>true).
        where("branches.name like '%#{term}%'").all
    when 'status'
      @branches = Branch.includes(:country).where(:is_active=>true).all
      if ['bad','error','no activity'].include?(term)
        @branches = @branches.select{|b| b.unhealth?}
      else
        @branches = @branches.select{|b| !b.unhealth?}
      end
#      @branches = Branch.includes(:country).where(:is_active=>true).
#        where("branches.status like '%#{term}%'").all   
    end
    render :partial=>'search_results', :layout=>false, :content_type=>'text'
  end
  
  def branch
    b = Branch.find_by_id params[:branch_id]
    if b && b.client_ip_address
      t = b.client_ip_address
    else
      t = ''
    end
    render :text=>t, :content_type=>'text',:layout=>false
  end
end