class BranchController < ApplicationController
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
    text=%{{"forum":"#{@branch.forum_type}","forum_ui":"#{@branch.forum_type_ui}", "branch":"#{@branch.name}"}}
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
          text = %{{"error": "notice", "msg": "Branch #{msg}"}} 
        rescue Mysql2::Error => e
          text = %{{"error": "error", "msg": "MySQL error #{e.message}"}}
        rescue Exception=>e
          text = %{{"error": "error", "msg": "Exception #{e.message}"}}
        end
      end
      render :text=>text,:content_type=>"application/text", :layout => false
    end
end