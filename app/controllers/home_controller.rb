class HomeController < ApplicationController
  skip_filter :authorize
  include HomeHelper

  def index
   # started = Branch.message_time_span.days.ago.to_s(:db)
   # ended = Time.now.to_s(:db)
   # @alerts = Stat.new(started, ended).no_activity
   # @messages = Stat.new(started, ended).new_messages
   # @calls = Stat.new(started, ended).number_of_calls
  end

  def header
    activity = render_to_string :partial=>'shared/activity_ajax', :formats=>["html"]
#    render :text=>"{\"activity\":\"#{activity}\",\"alerts\":\"#{@alerts[:unique]}\",\"calls\":\"#{@calls[:total]}\",\"messages\":\"#{@messages[:total]}\"}", :content_type=>"text" and return
    render :json=>{:activity=>activity,
      :alerts=>@alerts[:unique],
      :calls=>@calls[:total],
      :messages=>@messages[:total]},
        :content_type=>"text", 
        :layout=>false
  end

  protected
 
end
