module EventsHelper
  def page_column(record, column=nil)
     p = Page.find_by_id(record.page_id)
     p.name if p 
  end
  def action_column(record, column=nil)
    p = Action.find_by_id(record.action_id)
    p.name if p
  end
end