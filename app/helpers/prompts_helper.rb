module PromptsHelper
  def url_column(record, input_name)
    "<a href='#{record.url}'>#{record.url}</a>".html_safe
  end
   
  def name_form_column(record, input_name)
    if record.kind_of? Prompt
      id = record.name
      options = Message.all.map{|a| [a.name, a.name]}
      select_tag 'record[name]', options_for_select(options, id), :id=>'message-name'
   else
      m = input_name.delete(:name)
      input_name[:class] = input_name[:class] + " text-input"
      text_field :record, :name, input_name
    end
  end
  def sound_file_form_column(record, input_name)
     file_column_field 'record', :sound_file, :size=>'25',:onkeypress=>""
  end
end
