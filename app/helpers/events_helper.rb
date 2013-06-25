module EventsHelper
  def page_column(record, column=nil)
     p = Page.find_by_id(record.page_id)
     p.name if p 
  end
  def action_column(record, column=nil)
    p = Action.find_by_id(record.action_id)
    p.name if p
  end
  def identifier_column(record, column=nil)
    if record.identifier =~ /^http|https/
      uri = URI(record.identifier)
      "<a href='#{record.identifier}'>#{uri.path.split('/')[-3..-1].join('/')}</a>".html_safe
    else
      record.identifier
    end
  end
end