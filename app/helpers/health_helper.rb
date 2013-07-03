module HealthHelper
    def no_activity_form_column(record, input_name)
      "<input type='text' name='record[no_activity]' value='#{record.no_activity}' />".html_safe
    end
    
    def phone_carrier_form_column(record, input_name)
       options = SMSFu.carriers.sort.collect{ |carrier| [carrier[1]["name"], carrier[0]] }
       options.unshift ["--Select a Carrier--", nil]
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
      text_field_tag 'record[cell_phone]', record.cell_phone, :placeholder=>"2021234567"
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
  def status_column(record, column=nil)
    if record.kind_of? Health
      seconds = (Time.now.to_i - record.last_event.to_i)
      hours = seconds/3600.0
      if hours > record.no_activity
        "<img class='red-light' width='25' src='assets/red.png' />".html_safe
      else
        "<img class='green-light' width='25' src='assets/green.png' />".html_safe
      end
    end
  end
end