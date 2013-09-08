class HomeController < ApplicationController
  skip_filter :authorize
  def index
    started = Branch.message_time_span.days.ago.to_s(:db)
    ended = Time.now.to_s(:db)
    @alerts = Stat.new(started, ended).alerted
    @messages = Stat.new(started, ended).messages
    @calls = Stat.new(started, ended).number_of_calls
  end
end