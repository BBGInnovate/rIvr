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
  
  def audio_players(branch)
    audios = []
    template = branch.forum_type.camelcase.constantize
    intro = template.find_me(branch.id, 'introduction')
    audios << ['Introduction', audio_tag(intro), edit_tag(intro)]  
    case branch.forum_type
    when 'report' 
      headline = template.find_me(branch.id, 'headline')
      audios << ['Headline News', 'Feed Source', edit_tag(headline)]  
      bye = template.find_me(branch.id, 'goodbye')
      audios << ['Goodbye', audio_tag(bye), edit_tag(bye)]  
    when 'vote'
      vote = template.find_me(branch.id, 'candidate')
      audios << ['Participate', audio_tag(vote), edit_tag(vote)]  
    when 'bulletin' 
      bulletin = template.find_me(branch.id, 'bulletin_question')
      audios << ['Ask the communite', audio_tag(bulletin), edit_tag(bulletin)]  
    end
  end
  def audio_tag(template)
    if template.audio_link
    html = %{<a id="#{template.id}" class="audio {ogg:'#{template.audio_link}',downloadable:false,autoplay:false, inLine:true}"
          href="#{template.audio_link}">
          #{template.audio_link}</a>
        <button onclick="$('##{template.id}').mb_miniPlayer_stop();">stop</button>
        <button onclick="$('##{template.id}').mb_miniPlayer_play();">play</button>}
    else
      html = 'No audio file uploaded'
    end
    html.html_safe    
  end 
  def edit_tag(template)
  html = %{<input id="branch-name" type="hidden" value="#{template.branch_id}" name="branch" /><input type="hidden" value="#{template.branch.forum_type}" name="forum-type"/><a href='' class='square' id='#{template.name}'>&nbsp;&nbsp;Edit</a>}
    html.html_safe
  end
end
