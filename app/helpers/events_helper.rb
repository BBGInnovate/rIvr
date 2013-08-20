module EventsHelper
  def page_column(record, column=nil)
     p = Page.find_by_id(record.page_id)
     p.name if p 
  end
  def actions_column(record, column=nil)
    if record.kind_of? Event
      p = Action.find_by_id(record.action_id)
      p.name if p
    else

    end
  end
  def identifier_column(record, column=nil)
    if record.identifier =~ /^http|https/
      uri = URI(record.identifier)
      "<a href='#{record.identifier}'>#{uri.path.split('/')[-3..-1].join('/')}</a>".html_safe
    elsif record.identifier =~ /\.\.\/Uploads\//
      f = record.identifier.split("/").last
      link_to "File", f,:target => '_blank', :title=>record.identifier
    elsif record.identifier =~ /^\d+\.wav$/
      entry = Entry.find_by_dropbox_file record.identifier
      if entry
        link_to entry.dropbox_file, play_entry_path(entry), :target => '_blank'
      else
        record.identifier
      end
    elsif !!record.identifier
      "<abbr title='#{record.identifier}'>#{record.identifier.truncate(18)}</abbr>".html_safe
    else
      ""
    end
  end
end
