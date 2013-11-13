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
    action_type = Branch.forum_types.detect{|e| e==params[:action_type]}
    if action_type 
      @branch.forum_type = action_type
      @branch.save
      audios = ''
    end
    hint = ''
    if @branch.forum_type
      tmp = @branch.send "#{@branch.forum_type.pluralize}"
      if tmp.latest.size == 0
        # hint = "You must upload the voice forum audio files by clicking Edit Forum link to the left"
      end
    end
    if params[:action_type] == 'privew-voice-forum'
      audios = render_to_string :partial=>'shared/audio_player', :formats=>["html"]
    end
    render :json=>{:html=>audios,
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
          text = %{{"error": "notice", "msg": "Branch #{msg}", "branch":"#{@branch.id}", "branch_name":"#{@branch.name}"}} 
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
    
    def select_forum
      if request.get?
        @branch = Branch.find_by_id params[:id]
        html = render_to_string :partial=>'select_forum', :formats=>["html"], :locals=>{:action=>'select'}
        render :json=>{:html=>html},
            :content_type=>"text", 
            :layout=>false
      else
        @branch = Branch.find_by_id params[:id]
        forum_name = params[:forum_name]
        vs = VotingSession.find_me(forum_name, @branch)
        @branch.voting_sessions.each do |v|
          if v.id != vs.id
            v.update_attribute :current, false
          else
            v.update_attribute :current, true
          end
        end
          
        vs.update_attribute(:current, true) if vs
        html="Forum : #{vs.name} is selected."
        render :json=>{:html=>html},
            :content_type=>"text", 
            :layout=>false
      end
    end
    
    def preview_forum
      @branch= Branch.find_me(params[:id])
      html = render_to_string :partial=>'shared/audio_player', :formats=>["html"]
      render :json=>{:html=>html},
            :content_type=>"text", 
            :layout=>false
    end
  
    def activate_forum
      if request.get?
        @branch = Branch.find_by_id params[:id]
        html = render_to_string :partial=>'activate_forum', :formats=>["html"], :locals =>{:action=>'activate'}
        render :json=>{:html=>html},
            :content_type=>"text", 
            :layout=>false
      else
        @branch = Branch.find_by_id params[:id]
        if params[:forum_name]
          forum_name = params[:forum_name]
          vs = VotingSession.find_me(forum_name, @branch)
        else
          forum_name = @branch.current_forum_session.name
          vs = @branch.current_forum_session
        end
        if !!vs
          @branch.voting_sessions.each do |v|
            if v.id != vs.id
              v.update_attributes :is_active=>false
            else
              v.update_attributes :is_active=>true
            end
          end
          html="Forum : #{vs.name} is activated."
          @branch.generate_forum_feed_xml
        else
          html="Forum : #{forum_name } not found."
        end
        render :json=>{:html=>html},
            :content_type=>"text", 
            :layout=>false
      end
    end
    
    def syndicate_forum
      @branch= Branch.find_me(params[:id])
      @results=[]
      html = render_to_string :partial=>'modals/search_rsults', :formats=>["html"]
      render :json=>{:html=>html},
            :content_type=>"text", 
            :layout=>false
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
    
    def upload_headline_audio
      branch=Branch.find_by_id params[:branch_id]
      temp = params[:branch] 
      sound_file = temp.delete(:sound)
      # identifier = temp.delete(:identifier)
      vs = branch.current_forum_session # VotingSession.find_me identifier, branch
      if sound_file # from preview
        headline = branch.reports.find_or_create(:branch_id=>branch.id,
             :name=>'headline', :voting_session_id=>vs.id)
                
           
        uploaded = headline.upload_headline(sound_file)
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
    
  def validate_forum
    id = params[:id]
    @result = params[:result].to_i
    @branch = Branch.find_by_id id
    if !!@branch
       case @branch.forum_type
       when 'report'
          @err = validate_report(@branch)
       when 'vote'
          @err = validate_vote(@branch, @result)
       when 'bulletin'
          @err = validate_bulletin(@branch)
       else 
          logger.info "Unknown Forum Type"
       end
    end
    render :layout=>false
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
  
  protected 
  
  def validate_report(branch)
     txt = []
     temps = branch.reports.current
     intro = temps.detect{|t| t.name=='introduction'}
     goodbye = temps.detect{|t| t.name=='goodbye'}
     feed = branch.branch_feeds.where(:forum_session_id=>branch.current_forum_session.id).last
     if !feed
       txt << "Branch <b>Feed Source</b> is not configured."
     else
       if feed.feed_source == 'static_rss'
         if !feed.feed_url
           txt << "Branch <b>Feed Source</b> is rss, but Feed URL is not configured."
         end
       end
     end
     if !intro
       txt << "<b>Introduction</b> prompt audio is not uploaded."
     end
     if !goodbye 
       txt << "<b>Goodbye</b> prompt audio is not uploaded."
     end
     txt
  end
  
  def validate_bulletin(branch)
     txt = []
     temps = branch.bulletins.current
     intro = temps.detect{|t| t.name=='introduction'}
     question = temps.detect{|t| t.name=='question'}
     listen = temps.detect{|t| t.name=='listen'}
     if !intro
       txt << "<b>Introduction</b> prompt audio is not uploaded."
     end
     if !question
       txt << "<b>Ask the community</b> prompt audio is not uploaded."
     end
     if !listen
       txt << "<b>Listen Messages</b> prompt audio is not uploaded."
     end
     txt
  end
  
  def validate_vote(branch, result)
     txt = []
     temps = branch.votes.current
     intro = temps.detect{|t| t.name=='introduction'}
     candidate = temps.detect{|t| t.name=='candidate'}
     comment = temps.detect{|t| t.name=='comment'}
     
     intro_result = temps.detect{|t| t.name=='introduction_result'}
     candidate_result = temps.detect{|t| t.name=='candidate_result'}
     listen_result = temps.detect{|t| t.name=='listen_result'}
     
     if result==0
       if !intro
         txt << "<b>Introduction</b> prompt audio is not uploaded."
       end
       if !candidate
         txt << "<b>Participate</b> prompt audio is not uploaded."
       end
       if !comment
         txt << "<b>Leave Comment</b> prompt audio is not uploaded."
       end
     else
       if !intro_result
         txt << "<b>Introduction</b> prompt audio is not uploaded."
       end
       if !candidate_result
         txt << "<b>Results</b> prompt audio is not uploaded."
       end
       if !listen_result
         txt << "<b>Opinion Board</b> prompt audio is not uploaded."
       end
     end
     txt
  end
  
end
