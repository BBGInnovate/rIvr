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
    elsif @branch.forum_type == 'poll'
      if params[:result].to_i == 1
        @question="Poll Result"
      else
        @question="Poll Question"
      end
    elsif @branch.forum_type == 'vote'
      if params[:result].to_i == 1
        @question="Results"
      else
        @question="Vote/Poll"
      end  
    end
    @temp_partial = @branch.forum_type
    if params[:result] && ['vote','poll'].include?(@branch.forum_type)
      @temp_partial = @temp_partial + "_result"
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
#    @template = branch.forum_type.camelcase.constantize.find_me(branch.id, params[:name])
#    always create a new record
    @template = branch.forum_type.camelcase.constantize.new :branch_id=>branch.id, 
      :name=>params[:name]
    # if !@template.valid?
      # flash[:error] = @template.class.name + " : " + @template.errors.full_messages.join(", ")
    # else
      @template.save :validate=>false
    # end
    if branch.forum_type == 'report'
      @headline="Headline News"
      @goodbye="Goodbye"
    elsif branch.forum_type == 'bulletin'
      @question="Bulletin Board"
      @listen_bulletin="Listen Message"
      @record_bulletin="Record Message"
    elsif branch.forum_type == 'vote'

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
      if @template.kind_of?(Vote)
        @template.identifier = temp[:identifier]
      end
      if @template.valid?
        @template.save
        flash[:notice] = "#{@template.name.titleize} file " +
              File.basename(@template.dropbox_file) +
              " has been uploaded"
      else
        @save = true
        flash[:error] = @template.class.name + " : " + @template.errors.full_messages.first
      end
    else
      # Preview the sound
      file = temp[:sound]
      if !file
        @preview = true if !!@template.dropbox_file
      else
        @template.upload_to_dropbox(file)
        @template.save :validate=>false
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