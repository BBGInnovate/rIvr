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
end
