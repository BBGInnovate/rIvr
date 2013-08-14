class TemplatesController < ApplicationController
  #  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  layout 'application'
  
  def new
    # params[:report] params[:branch] params[:name]
    b = Branch.find_me(params[:branch])
    if params[:type] == 'report'
      @template = Report.find_me(b.id, params[:name])
    elsif params[:type] == 'bulletin'
      @template = Bulletin.find_me(b.id, params[:name])
    elsif params[:type] == 'vote'
      @template = Vote.find_me(b.id, params[:name])
    end
    if !!@template.dropbox_file
      flash[:notice] = "#{params[:name].titleize} file " +
      File.basename(@template.dropbox_file) +
      " has been uploaded"
    end
    @preview = false
    render :layout=>'templates'
  end

  def create
    temp = params[:report] || params[:bulletin] || params[:vote]
    @template = Report.find_by_id temp[:id]
    @preview = false
    # save button pressed
    if params[:commit] == 'Save'
      @template.is_active=true
      @template.save!
      flash[:notice] = "#{params[:name].titleize} file " +
      File.basename(@template.dropbox_file) +
      " has been uploaded"
    elsif params[:commit] == 'Cancel'
      render :index and return
    else
      # Preview the sound
      file = temp[:sound]
      if !file
        @preview = true if !!@template.dropbox_file
      else
        @template.upload_to_dropbox(file)
        @preview = true
      end
    end
    render :action=>'new', :layout => 'templates'
  end

  def headline
    # params[:branch] == 'oddi'
    if request.post?
      if params[:commit] == 'Save'
        opt = params[:configure]
        branch = Branch.find_by_name opt[:branch]
        feed_source= opt[:feed_source]
        @option = Configure.find_me(branch, "feed_source")
        @option.feed_source = feed_source
        @option.save!
      end
      render :index and return
    else
      branch = Branch.find_me(params[:branch])
      @option = Configure.find_me(branch, "feed_source")
      render :layout => 'templates'
    end
  end

end