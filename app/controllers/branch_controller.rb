class BranchController < ApplicationController
  layout 'branch'
  def index
    if params[:branch]
      @branch = Branch.find_by_name params[:branch]
    else
      @branch = nil
    end
  end
  def show
    @branch= Branch.find_me(params[:id])
    if params[:forum_type]
      @branch.forum_type = params[:forum_type]  # .split("_").last
      @branch.save
     # render :text=>branch.forum_type and return 
    end
    hint = ''
    if @branch.forum_type
      tmp = @branch.send "#{@branch.forum_type.pluralize}"
      if tmp.latest.size == 0
        hint = "You must upload the voice forum audio files by clicking Edit Forum link to the left"
      end
    end
    text=%{{"hint":"#{hint}","forum":"#{@branch.forum_type}","forum_ui":"#{@branch.forum_type_ui}", "branch":"#{@branch.name}"}}
    render :text =>text ,:content_type=>'application/text',:layout=>false and return

  end
  def new
      flash[:notice] = nil
      if params[:branch_id]
        @branch = Branch.find_by_id(params[:branch_id]) || @branch = Branch.new
      else
        @branch = Branch.new
      end
      render :layout=>false # 'templates'
  end
  
    def create
      temp = params[:branch]
      @branch = Branch.find_by_name temp[:name]
      feed_source = temp.delete(:feed_source)
      feed_url = temp.delete(:feed_url)
      feed_limit = temp.delete(:feed_limit)
      if @branch
        @branch.attributes = temp
        msg = "#{@branch.name.titleize} saved"
      else
        @branch = Branch.new temp
        msg = "#{@branch.name.titleize} created"
      end
        
      if !@branch.valid?
        text = %{{"error": "error", "msg": "Invalid #{@branch.errors.full_messages.first}"}}
      else 
        begin
          @branch.save
          @branch.feed_source = feed_source
          @branch.feed_url = feed_url
          @branch.feed_limit = feed_limit
          text = %{{"error": "notice", "msg": "Branch #{msg}", "branch":"#{@branch.id}"}} 
        rescue Mysql2::Error => e
          text = %{{"error": "error", "msg": "MySQL error #{e.message}"}}
        rescue Exception=>e
          text = %{{"error": "error", "msg": "Exception #{e.message}"}}
        end
      end
      render :text=>text,:content_type=>"application/text", :layout => false
    end
end