module HomeHelper
  def activity
    htm="<h2>Top Activity<\/h2>"
    htm<<"<table border='0' cellspacing='0' cellpadding='0'>"
    Branch.top_activity.each do |e|

      htm<<"<tr><td class='flag'>"
      htm<<"<img src='#{e.branch.country_flag_url}' width='35' height='34' alt='flag missing' /></td>"
      htm<<"<td class='country'>#{e.branch.country.name}</td>"
      htm<<"<td class='phone'>#{@calls[e.branch.id] || 0}</td>"
      htm<<"<td class='message left-nav-bar' data-url='/entries'>"
      htm<<"#{@messages[e.branch_id] || 0}</td>"
      htm<<"<td class='alert left-nav-bar' data-url='/health'>"

      if e.branch.unhealth?
        htm<<"<img class='red-light' width='15' height='15' src='/assets/red.png' />"
      else
        htm<<"<img class='red-light' width='15' height='15' src='/assets/red.png' />"
      end  
      htm<<"</td>"
      htm<<"</tr>"
    end
    htm<<"</table>"
    htm<<"<script>blinkeffect('img.red-light');</script>"
    htm
  end

end
