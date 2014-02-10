module ApplicationHelper
  
  def date_picker
    html = "<div class='datepicker-wrapper'>"
    html << "<label class='calendar' for='start_date'>Start Date:</label>"
    html << "<input type='text' class='datepicker' id='start_date' name='start_date' />"
    html << "<p class=''></p>"
    html << "<label class='calendar' for='end_date'>End Date:</label>"
    html << "<input type='text' class='datepicker' id='end_date' name='end_date' />"
    html << "</div>"
    html.html_safe
  end
  def player(audio, download=true)
    return '' unless !!audio.dropbox_file
    eid = audio.id
    # /entries/<%=eid%>/play
    html = %{<a id='#{eid}' class="audio2 {ogg:'#{audio.audio_link}',autoplay:false, downloadable:false,inLine:true}"
       href='#{audio.audio_link}'>#{File.basename(audio.dropbox_file)}</a>}
    if download
      html << "<a target='_blank' title='Download #{audio.dropbox_file}' href='#{audio.audio_link}'>Download</a>"
    end
    #
    #  <object data="#{audio.audio_link}" type="application/x-mplayer2" width="245" height="30" autoplay="false">
    #     <param name="filename" value="#{audio.audio_link}" />
    #     <param name="controller" value="true" /> 
    #     <param name="autoplay" value="false" />
    #     <param name="autostart" value="0" />
    #  </object>
    html.html_safe  
  end
  def format_seconds(total_seconds)
    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)
    format("%02d:%02d:%02d", hours, minutes, seconds)
  end
  def branch_form_column(record, input_name)
    if !record.kind_of?(Branch)
    id = record.branch_id rescue 0
      options = Branch.where("is_active=1").map{|b| [b.name, b.id]}
      options.unshift ["None","0"]
      select_tag 'record[branch_id]', options_for_select(options, id), :style=>''
    else
        super
    end
  end
  def country_form_column(record, input_name)
    if record.kind_of? Branch
      id = record.country_id
      options = Country.all.map{|b| [b.name, b.id]}
      select_tag 'record[country_id]', options_for_select(options, id), :style=>''
    else
        super
    end
  end 
  def country_column(record, input_name)
    if record.kind_of? Branch
      !!record.country ? record.country.name : nil
    else
      super
    end
  end
  
  def branch_column(record, input_name)
    if record.kind_of? VotingSession
      !!record.branch ? record.branch.name : nil
    else
      super
    end
  end
  def start_date_column(record, input_name)
    if record.kind_of? VotingSession
       record.start_date ? record.start_date.to_s(:db) : 'N/A'
    else
      super
    end
  end
  def end_date_column(record, input_name)
    if record.kind_of? VotingSession
      record.end_date ? record.end_date.to_s(:db) : 'N/A'
    else
      super
    end
  end
  def audio_players(branch)
    audios = []
    records = branch.send(branch.forum_type.pluralize).current
    case branch.forum_type
    when 'report'
      intro = records.detect{|t| t.name=='introduction'}
      intro = create_template(branch, 'introduction') if !intro
      audios << ['Introduction', audio_tag(intro), edit_tag(intro)] 
      headline = branch.reports.headline
      if branch.feed_source != 'static_rss'
        audio = audio_tag(headline)
      else
        audio = 'Static RSS'
      end
      audios << ['Headline News', audio, edit_tag(headline)]  
      bye = records.detect{|t| t.name=='goodbye'}
      bye = create_template(branch, 'goodbye') if !bye
      audios << ['Goodbye', audio_tag(bye), edit_tag(bye)]  
    when 'vote'
      intro = records.detect{|t| t.name=='introduction'}
      intro = create_template(branch, 'introduction') if !intro
      audios << ['Introduction', audio_tag(intro), edit_tag(intro)] 
      vote = records.detect{|t| t.name=='candidate'}
      vote = create_template(branch, 'candidate') if !vote
      audios << ['Participate', audio_tag(vote), edit_tag(vote)]
      comment = records.detect{|t| t.name=='comment'}
      comment = create_template(branch, 'comment') if !comment
      audios << ['Leave Comment', audio_tag(comment), edit_tag(comment)]
      
      intro = records.detect{|t| t.name=='introduction_result'}
      intro = create_template(branch, 'introduction_result') if !intro
      audios << ['Introduction Result', audio_tag(intro), edit_tag(intro)] 
      vote = records.detect{|t| t.name=='candidate_result'}
      vote = create_template(branch, 'candidate_result') if !vote
      audios << ['Vote Result', audio_tag(vote), edit_tag(vote)]
      listen = records.detect{|t| t.name=='listen_result'}
      listen = create_template(branch, 'listen_result') if !listen
      audios << ['Opinion Board', audio_tag(listen), edit_tag(listen)] 
    when 'bulletin' 
      intro = records.detect{|t| t.name=='introduction'}
      intro = create_template(branch, 'introduction') if !intro
      audios << ['Introduction', audio_tag(intro), edit_tag(intro)] 
      bulletin = records.detect{|t| t.name=='question'}
      bulletin = create_template(branch, 'question') if !bulletin
      audios << ['Ask the communite', audio_tag(bulletin), edit_tag(bulletin)]  
      listen = records.detect{|t| t.name=='listen'}
      listen = create_template(branch, 'listen') if !listen
      audios << ['Listen Messages', audio_tag(listen), edit_tag(listen)] 
      record = records.detect{|t| t.name=='record_message'}
      record = create_template(branch, 'record_message') if !record
      audios << ['Leave Messages', audio_tag(record), edit_tag(record)] 
    end
  end
  def create_template(branch, name)
     tmp = branch.send(branch.forum_type.pluralize).create :name=>name,
             :voting_session_id=>branch.current_forum_session.id
  end
  
  def Oldaudio_players(branch)
    audios = []
    template = branch.forum_type.camelcase.constantize
     
    case branch.forum_type
    when 'report'
      intro = template.find_me(branch.id, 'introduction')
      audios << ['Introduction', audio_tag(intro), edit_tag(intro)] 
      headline = branch.reports.headline
      if branch.feed_source != 'static_rss'
        audio = audio_tag(headline)
      else
        audio = 'Static RSS'
      end
      audios << ['Headline News', audio, edit_tag(headline)]  
      bye = template.find_me(branch.id, 'goodbye')
      audios << ['Goodbye', audio_tag(bye), edit_tag(bye)]  
    when 'vote'
      intro = template.find_me(branch.id, 'introduction')
      audios << ['Introduction', audio_tag(intro), edit_tag(intro)] 
      vote = template.find_me(branch.id, 'candidate')
      audios << ['Participate', audio_tag(vote), edit_tag(vote)]
      
      comment = template.find_me(branch.id, 'comment')
      audios << ['Leave Comment', audio_tag(comment), edit_tag(comment)]
      
      intro = template.find_me(branch.id, 'introduction_result')
      audios << ['Introduction Result', audio_tag(intro), edit_tag(intro)] 
      vote = template.find_me(branch.id, 'candidate_result')
      audios << ['Vote Result', audio_tag(vote), edit_tag(vote)]
      listen = template.find_me(branch.id, 'listen_result')
      audios << ['Opinion Board', audio_tag(listen), edit_tag(listen)] 
    when 'bulletin' 
      intro = template.find_me(branch.id, 'introduction')
      audios << ['Introduction', audio_tag(intro), edit_tag(intro)] 
      bulletin = template.find_me(branch.id, 'bulletin_question')
      audios << ['Ask the communite', audio_tag(bulletin), edit_tag(bulletin)]  
      listen = template.find_me(branch.id, 'listen')
      audios << ['Listen Messages', audio_tag(listen), edit_tag(listen)] 
    end
  end
  def audio_tag(template)
    html = 'No audio file uploaded'
    if !template
      return html
    end
    audio_link = !!template.audio_link ? template.audio_link : nil
    if audio_link
    html = %{<a id="#{template.id}" class="audio {ogg:'#{template.audio_link}',downloadable:false,autoplay:false, inLine:true}"
          href="#{template.audio_link}">
          #{template.audio_link}</a>
        <button onclick="$('##{template.id}').mb_miniPlayer_stop();">stop</button>
        <button onclick="$('##{template.id}').mb_miniPlayer_play();">play</button>}
    else
      
    end
    html.html_safe    
  end
  def edit_tag(template)
  html = %{<input id="branch-name" type="hidden" value="#{template.branch_id}" name="branch" /><input type="hidden" value="#{template.branch.forum_type}" name="forum-type"/><a href='' class='square' id='#{template.name}'>&nbsp;&nbsp;Edit Forum</a>}
    html.html_safe
  end
end
