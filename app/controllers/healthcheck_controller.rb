class HealthcheckController < ApplicationController
#  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
    
  layout 'application'
  
  def index
    @branches = Branch.includes(:country).where(:is_active=>true).all

  end
  
  def search
    search_for = params[:branch][:search]
    search_term = params[:search_term]
    case search_for
    when 'country'
      @branches = Branch.includes(:country).where(:is_active=>true).
        where("countries.name like '#{search_term}'").all
    when 'name'
      @branches = Branch.includes(:country).where(:is_active=>true).
        where("branches.name like '#{search_term}'").all
    when 'status'
      @branches = Branch.includes(:country).where(:is_active=>true).
        where("branches.status like '#{search_term}'").all   
    end
    
  end
end