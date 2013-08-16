class TemplatesController < ApplicationController
  #  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  layout 'application'
  
  def index
    @branch_name = params[:branch] || 'oddi'
    @forum_type = params[:type] || 'report'
  end
  # For upload voice prompt voice forum
  # voice forum type must be one of report | bulletin | vote
  # prompt name must be one of introduction | goodbye | question
  # query format:
  # /templates/new?branch=tripoli&type=report&name=introduction
  def new
    flash[:notice] = nil
    b = Branch.find_me(params[:branch])
    if params[:type] == 'report'
      @template = Report.find_me(b.id, params[:name])
    elsif params[:type] == 'bulletin'
      @template = Bulletin.find_me(b.id, params[:name])
    elsif params[:type] == 'vote'
      @template = Vote.find_me(b.id, params[:name])
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
        flash[:notice] = "#{@option.value} saved"
      end
      render :layout => false
    else
      branch = Branch.find_me(params[:branch])
      @option = Configure.find_me(branch, "feed_source")
      render :layout => false
    end
  end

end