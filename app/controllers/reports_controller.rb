# require 'iconv'
require 'csv'

class ReportsController < ApplicationController
#   before_filter :login_required
  before_filter :init
#  before_filter :get_variables  #, :only=>[:content]
  # BOM = "\377\376" # Byte Order Mark
#  before_filter :stats_lookup
#  layout false
  def init
    @controller = request.filtered_parameters['controller']
    @title = I18n.t('pages.admin_charities.title')
    @report_name = "Activity Reports"
    if params[:start_date]
      started = params[:start_date]
      ended = params[:end_date]
    else
      started = Branch.message_time_span.days.ago.to_s(:db)
      ended = Time.now.to_s(:db)
    end
    @start_date = started
    @end_date = ended
    if request.post?
      # @branches = Branch.includes(:country).where(:is_active=>true).select("country_id, contries.id, contries.name, branches.name").all
      
      @branches = Branch.where(["id in (?)", params[:branch_id]])
      
      @stats = Stat.new(started, ended)
      # @alerts = @stats.alerted
      @messages = @stats.messages
      @calls = @stats.number_of_calls
      @call_times = @stats.call_times
      @listened = @stats.listened
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
  
  def index
    render :layout=>false, :content_type=>'text/html'
  end
  
  def create
    content
  end
  
  def branch_report_title
      title = [
            'Branch Name',
            'Date',
            'Number of Callers', # Stat.new.number_of_calls
            'Average time listening',
            'Average total call time', # Stat.new.call_times[:average]
            'Number of Messages Left', # Stat.new.messages[:total]
            'Country'
            ]
  end
    
  def branch_report_rows
    @rows = []
    @branches.each do | b |
      row = {}
      row['Branch Name'] = b.name
      row['Date'] = Time.now.to_s(:db)
      row['Number of Callers'] = @calls[b.id][:total]
      row['Average time listening'] = @listened[b.id][:average]
      row['Average total call time'] = @call_times[b.id][:average]
      row['Number of Messages Left'] = @messages[b.id][:total]
      row['Country'] = b.country.name
      @rows << row
    end
    puts "RRRR #{@rows.size}"
    @rows
  end
      
  def content
    flash[:error] = nil
    respond_to do |format|
      filename = "dl_#{Time.now.strftime('%Y%m%d')}.csv".downcase
      format.csv { send_content(filename) }
      format.html { get_data; render :content, :layout=>false}
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
    content = CSV.generate(:col_sep => ",") do |csv|
      csv << branch_report_title
      branch_report_rows.each do | row |
        csv << [row['Branch Name'], row['Date'],row['Number of Callers'],
        row['Average time listening'],row['Average total call time'],
        row['Number of Messages Left'],row['Country'] ]
      end
    end
    bom = "\377\376" # Byte Order Mark
    content = content.encode('UTF-8', :invalid => :replace, :replace => '').encode('UTF-8')  
    puts "AAAAA #{content.inspect}"
    send_data content, :filename => filename,
      :type => 'text/csv; charset=iso-8859-1; header=present'
  end
  
  def get_data

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
