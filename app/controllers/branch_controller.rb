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
      @branch = Branch.new
      render :layout=>false # 'templates'
    end
  
    def create
      temp = params[:branch]
      @branch = Branch.new temp
      if !@branch.valid?
        text = %{{"error": "error", "msg": "Invalid #{@branch.errors.full_messages.first}"}}
      else 
        begin
          @branch.save
          text = %{{"error": "notice", "msg": "Branch #{@branch.name.titleize} created"}} 
        rescue Mysql2::Error => e
          text = %{{"error": "error", "msg": "MySQL error #{e.message}"}}
        rescue Exception=>e
          text = %{{"error": "error", "msg": "Exception #{e.message}"}}
        end
      end
      render :text=>text,:content_type=>"application/text", :layout => false
    end
end