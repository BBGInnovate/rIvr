class HealthcheckController < ApplicationController
#  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
    
  layout 'application'
  
  def index
    if !@branches 
      @branches = Branch.includes(:country).where(:is_active=>true).all
    end
  end
  
  def search
    search_for = params[:search_for]
    term = params[:term]
    case search_for
    when 'country'
      @branches = Branch.includes(:country).where(:is_active=>true).
        where("countries.name like '%#{term}%'").all
    when 'name'
      @branches = Branch.includes(:country).where(:is_active=>true).
        where("branches.name like '%#{term}%'").all
    when 'status'
      @branches = Branch.includes(:country).where(:is_active=>true).
        where("branches.status like '%#{term}%'").all   
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