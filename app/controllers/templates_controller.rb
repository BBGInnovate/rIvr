class TemplatesController < ApplicationController
  #  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  layout 'branch'
  
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
      @question="Ask the community"
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
        @question="Participate"
      end  
    end
    @temp_partial = @branch.forum_type
    # params[:result] came from main.js branchManage.updateForumType 
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
        
#    if params[:name] == 'introduction'
#      Template.delete_all("is_active=0")
#    end

#    @template.save :validate=>false

    if branch.forum_type == 'report'
      @headline="Headline News"
      @goodbye="Goodbye"
    elsif branch.forum_type == 'bulletin'
      @question="Ask the community"
      @listen_bulletin="Listen Message"
      @record_bulletin="Record Message"
    elsif branch.forum_type == 'vote'
      if params[:result].to_i == 1
        @question="Results"
      else
        @question="Participate"
      end  
    end
#    if !!@template && !!@template.dropbox_file
#      flash[:notice] = "#{params[:name].titleize} file " +
#      File.basename(@template.dropbox_file) +
#      " has been uploaded"
#    end
    @preview = false
    render :layout=>false # 'templates'
  end

  def create
    branch=Branch.find_by_id params[:branch_id]
    temp = params[branch.forum_type.to_sym] # || params[:report] || params[:bulletin] || params[:vote]

#    @template = Template.find_by_id temp[:id]
#    branch=Branch.find_by_id temp[:branch_id]
    sound_file = temp.delete(:sound)
    identifier = temp.delete(:identifier)
    
    @template = Template.find_by_id temp.delete(:id)
    if !@template
      @template = branch.forum_type.camelcase.constantize.new temp
    end
    
    @preview = false
    if params[:todo] == 'preview'
      @template.identifier = identifier if @template.kind_of?(Vote)
      # Preview the sound
      if !sound_file
         @preview = true if !!@template.dropbox_file
      else
         @template.upload_to_dropbox(sound_file)
         @template.save :validate=>false
         @preview = true

         flash[:notice] = "#{@template.name_map(@template.name)} file " +
                              File.basename(@template.dropbox_file) +
                              " was uploaded to temperary folder"
      end
    # save button pressed
    elsif params[:todo] == 'save'
      @template.is_active=true
      if @template.valid?
        @template.save
        flash[:notice] = "#{@template.name_map(@template.name)} file " +
              File.basename(@template.dropbox_file) +
              " has been uploaded"
      else
        @save = true
        flash[:error] = @template.class.name + " : " + @template.errors.full_messages.first
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

  def forum_feed
    branch = Branch.find_by_name params[:branch]
    if branch
      branch.generate_forum_feed
      tmp_file = "#{DROPBOX.tmp_dir}/#{branch.name}/forum.xml"
      content = File.open(tmp_file, "r") {|file| file.read}
      send_data content,
            :filename=>"forum.xml",
            :type=>"text",
            :disposition=>'inline'
            
    end
  end
  def forum_type(branch)
    case branch.forum_type
    when 'vote'
      'Participate'
    when 'bulletin'
      'Ask the community'
    else
      t.titleize
    end
  end
  helper_method :forum_type
  
end