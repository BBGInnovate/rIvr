module HealthHelper
    def no_activity_form_column(record, input_name)
      "<input type='text' name='record[no_activity]' value='#{record.no_activity}' />".html_safe
    end
    
    def phone_carrier_form_column(record, input_name)
       options = SMSFu.carriers.sort.collect{ |carrier| [carrier[1]["name"], carrier[0]] }
       id = record.phone_carrier
       select_tag 'record[phone_carrier]', options_for_select(options, id), :style=>''    
    end
    
    def deliver_method_form_column(record, input_name)
      options = [['Email','email'],['Text Message','text']]
      id = record.deliver_method
      select_tag 'record[deliver_method]', options_for_select(options, id), :style=>''    
    end
    
    def email_form_column(record, input_name)
      text_field_tag 'record[email]', record.email
    end
    
    def cell_phone_form_column(record, input_name)
      text_field_tag 'record[cell_phone]', record.cell_phone
    end
    
  def last_event_column(record, column=nil)
    if record.last_event
      t = record.last_event.strftime("%Y/%m/%d %H:%M:%S")
      "<a href='#{list_event_path(record.event_id)}'>#{t}</a>".html_safe
    else
      ""
    end
  end
    
  def event_column(record, column=nil)
    if record.last_event
      record.event
    else
      ""
    end
  end

  def send_alarm_column(record, column=nil)
    if record.send_alarm
      "Yes"
    else
      "No"
    end
  end

end