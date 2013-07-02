class HomeController < ApplicationController
  skip_filter :authorize
  def index
    
  end
end