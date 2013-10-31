require 'soundcloud'
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
      @branch.forum_type = params[:forum_type]
      @branch.save
     # render :text=>branch.forum_type and return 
    end
    hint = ''
    if @branch.forum_type
      tmp = @branch.send "#{@branch.forum_type.pluralize}"
      if tmp.latest.size == 0
        # hint = "You must upload the voice forum audio files by clicking Edit Forum link to the left"
      end
    end
    audios = render_to_string :partial=>'shared/audio_player', :formats=>["html"]
    render :json=>{:audios=>audios,
                   :hint=>hint,
                   :forum=>@branch.forum_type,
                   :forum_ui=>@branch.forum_type_ui,
                   :branch=>@branch.name},
            :content_type=>"text", 
            :layout=>false
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
          # @branch.feed_source = feed_source
          # @branch.feed_url = feed_url
          # @branch.feed_limit = feed_limit
          text = %{{"error": "notice", "msg": "Branch #{msg}", "branch":"#{@branch.id}"}} 
        rescue Mysql2::Error => e
          text = %{{"error": "error", "msg": "MySQL error #{e.message}"}}
        rescue Exception=>e
          text = %{{"error": "error", "msg": "Exception #{e.message}"}}
        end
      end
      render :text=>text,:content_type=>"application/text", :layout => false
    end
    def destroy
      branch=Branch.find_by_id params[:id]
      if branch
        branch.is_active=false
        branch.save
        render :partial=>"branch_options",
          :layout=>false,:content_type=>'application/text'
      else
        render :text=>"branch not found for id : #{params[:id]}",
                  :layout=>false,:content_type=>'text'
      end
    end
    
    def activate_forum
      # /branch/activate_forum
      # :branch_id is voting_session_id
      vs = VotingSession.find_by_id params[:id]
      
      if vs
        vs.is_active = true
        vs.save
        text="Forum : #{vs.name} is activated and forum_feed.xml is generated."
      else
        text = 'Forum Title Not Found'
      end
      render :text=>text, :layout=>false,:content_type=>'application/text'
    end
    
    def sorted_entries
      if request.post?
         SortedEntry.update(params[:ids], params[:sorted])
         b = Branch.find_by_id params[:branch_id]
         b.generate_forum_feed_xml if b
         render :nothing=>true
      else
         
      end
    end
    
    def upload_report_audio
      branch=Branch.find_by_id params[:branch_id]
      temp = params[:branch] 
      sound_file = temp.delete(:sound)
      identifier = temp.delete(:identifier)
      vs = VotingSession.find_me identifier
      if sound_file # from preview
        headline = Report.create :branch_id=>branch.id,
           :name=>'headline', :voting_session_id=>vs.id
           
        uploaded = headline.upload_to_dropbox(sound_file)
        if uploaded
           text = "#{sound_file.original_filename} is uploaded"
           render :text=>text, :layout=>false,:content_type=>'application/text'
           return
        else
          text="Error in uploading report audio file"
          render :text=>text, :layout=>false,:content_type=>'application/text'
        end
      else
        text="No sound file provided"
        render :text=>text, :layout=>false,:content_type=>'application/text'
      end
      
    end
    
  def exchange_token
    u = URI.parse request.original_url
    port = u.port=='80' ? '' : ":#{u.port}"
    server = "#{u.scheme}://#{u.host}#{port}/branch/exchange_token"
   
    if params[:sec]
      client_id=params[:id]
      client_secret=params[:sec]
      session[:client_id] = client_id
      session[:client_secret] = client_secret
      # create client object with app credentials
      client = Soundcloud.new(:client_id => client_id,
                        :client_secret => client_secret,
                        :redirect_uri => "#{server}")
      # redirect user to authorize URL
      redirect_to client.authorize_url(:scope=>'non-expiring')
      # "https://soundcloud.com/connect?scope=non-expiring&response_type=code_and_token&client_id=#{client_id}&redirect_uri=#{server}"
    elsif params[:code]
      code = params[:code]
      client = Soundcloud.new(:client_id => session[:client_id],
                        :client_secret => session[:client_secret],
                        :redirect_uri => "#{server}")
      # exchange authorization code for access token
      code = params[:code]
      access_token = client.exchange_token(:code => code)
      #branch = Branch.find_by_soundcloud_client_id session[:client_id]
      #if branch
      #  branch.soundcloud_access_token = access_token.access_token
      #  branch.save
      #end
      render :nothing=>true # :action=>"close_me"
    else
      logger.info "Error #{request.url}"
    end
  end
end
