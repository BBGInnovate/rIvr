class HomeController < ApplicationController
  skip_filter :authorize
  include HomeHelper

  def index
#    puts "AAAAA " +request.inspect
#    puts "BBBBB " + request.filtered_parameters['controller']
    started = Branch.message_time_span.days.ago.to_s(:db)
    ended = Time.now.to_s(:db)
    @alerts = Stat.new(started, ended).alerted
    @messages = Stat.new(started, ended).messages
    @calls = Stat.new(started, ended).number_of_calls
  end

  def header
    index
    render :text=>"{\"activity\":\"#{activity}\",\"alerts\":\"#{@alerts[:total]}\",\"calls\":\"#{@calls[:total]}\",\"messages\":\"#{@messages[:total]}\"}", :content_type=>"text" and return
  end

  protected
 
end
