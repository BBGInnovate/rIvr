require 'iconv'

class ReportsController < ApplicationController
#   before_filter :login_required
  before_filter :init
#  before_filter :get_variables  #, :only=>[:content]
  # BOM = "\377\376" # Byte Order Mark
#  before_filter :stats_lookup
#  layout false
  def stats_lookup
      @branches = Branch.where(:is_active=>true).all
  end
  def index
    puts "AAAA " + params.inspect

    render :layout=>false, :content_type=>'text/html'
  end
  def create
    render :text=>'AAAAAA', :content_type=>'text'
  end
  
  def init
    @title = I18n.t('pages.admin_charities.title')
    @report_name = "Activity Reports"
    if params[:start_date]
      started = params[:start_date]
      ended = params[:end_date]
    else
      started = Branch.message_time_span.days.ago.to_s(:db)
      ended = Time.now.to_s(:db)
    end
    @alerts = Stat.new(started, ended).alerted
    @messages = Stat.new(started, ended).messages
    @calls = Stat.new(started, ended).number_of_calls
    @start_date = started
    @end_date = ended
  end
  
  def branches
    # call helper method charities, added content_type so the server
    # will not add <html><body> tags wrapped around <option> tags
    render :text=>@template.branches(0), :content_type=>'text'
  end
  
  def content
    flash[:error] = nil
    respond_to do |format|
      filename = "dl_#{Time.now.strftime('%Y%m%d')}.csv".downcase
      format.csv { send_content(filename) }
      format.html { get_data; render :content, :layout=>false}
    end
  end

  def new
    # prompt user for report start_date and end_date
    if !!params[:start_date]
      @start_date = Time.parse(params[:start_date]).beginning_of_day.utc
      @end_date = Time.parse(params[:end_date]).end_of_day.utc
    else
      @end_date = Time.now.utc
      @start_date = @end_date.beginning_of_day.utc
    end   
  end

  protected
  
  def access_denied
    respond_to do |format|
      format.html do
        store_location
        redirect_to "/"
      end
    end
  end

  def get_variables
    new
    @branch_id = params[:branch]
    @branch = Branch.find_by_id @branch_id.to_i
  end

  def send_content(filename)
    get_data
    content = @template.csv_helper(@data, @elements)
    send_data content, :filename => filename
  end
  
  def get_data
    range = "events.created_at #{(@start_date..@end_date).to_s(:db)}"
    conditions = [range]

    @data = klass.all(:include=>[:customer, :charity, :secondary_transaction],
       :conditions => conditions, :order=>order_by)

    table_elements
    @data
  end

 def order_by
   params[:order] =~ /(transaction|billing_statement)-(\w+)/
   o = $2
   a = ['asc','desc']
   if !session[o]
     session[o] = 'desc'
   else
     a.delete session[o]
     session[o] = a.to_s
   end

 end
 
 private 

end
