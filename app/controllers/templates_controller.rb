class TemplatesController < ApplicationController
  #  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  layout 'application'
  
  def index
    @branch_name = params[:branch] || 'oddi'
    @goodbye=nil
    @headline = nil
    @question = nil
    @listen_bulletin=nil
    @record_bulletin=nil
    @branch = Branch.find_me(@branch_name)
    if @branch.forum_type == 'report'
      @headline="Headline News"
      @goodbye="Goodbye"
    elsif @branch.forum_type == 'bulletin'
      @question="Bulletin Board"
      @listen_bulletin="Listen Message"
      @record_bulletin="Record Message"
    end
  end
  # For upload voice prompt voice forum
  # voice forum type must be one of report | bulletin | vote
  # prompt name must be one of introduction | goodbye | question
  # query format:
  # /templates/new?branch=tripoli&type=report&name=introduction
  def new
    flash[:notice] = nil
    @headline=nil
    @goodbye=nil
    @question = nil
    @listen_bulletin=nil
    @record_bulletin=nil
    branch = Branch.find_me(params[:branch])
    @template = branch.forum_type.camelcase.constantize.find_me(branch.id, params[:name])
    if branch.forum_type == 'report'
#      @template = Report.find_me(branch.id, params[:name])
      @headline="Headline News"
      @goodbye="Goodbye"
    elsif branch.forum_type == 'bulletin'
#      @template = Bulletin.find_me(branch.id, params[:name])
      @question="Bulletin Board"
      @listen_bulletin="Listen Message"
      @record_bulletin="Record Message"
    elsif branch.forum_type == 'vote'
#      @template = Vote.find_me(branch.id, params[:name])
    end
    if !!@template && !!@template.dropbox_file
      flash[:notice] = "#{params[:name].titleize} file " +
      File.basename(@template.dropbox_file) +
      " has been uploaded"
    end
    @preview = false
    render :layout=>false # 'templates'
  end

  def create
    temp = params[:report] || params[:bulletin] || params[:vote]
    @template = Template.find_by_id temp[:id]
    @preview = false
    # save button pressed
    if params[:todo] == 'save'
      @template.is_active=true
      @template.save!
      flash[:notice] = "#{@template.name.titleize} file " +
      File.basename(@template.dropbox_file) +
      " has been uploaded"
    else
      # Preview the sound
      file = temp[:sound]
      if !file
        @preview = true if !!@template.dropbox_file
      else
        @template.upload_to_dropbox(file)
        @preview = true
        flash[:notice] = "#{@template.name.titleize} file " +
              File.basename(@template.dropbox_file) +
              " was uploaded to temperary folder"
      end
    end
    render :action=>'new', :layout => false
  end

  # UI for selecting feed source from dropbox or static rss
  def headline
    if request.post?
      if params[:todo] == 'save'
        # params[:configure][:branch_id] == 'oddi'
        opt = params[:configure]
        branch = Branch.find_by_id opt[:branch_id]
        feed_source= opt[:feed_source]
        @option = Configure.find_me(branch, "feed_source")
        @option.value = feed_source
        @option.save!
        branch.generate_forum_feed
        flash[:notice] = "FEED SOURCE changed to #{@option.value}"
      end
      render :layout => false
    else
      branch = Branch.find_me(params[:branch])
      @option = Configure.find_me(branch, "feed_source")
      render :layout => false
    end
  end

end