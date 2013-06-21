module ConfigureHelper
  def feed_source_form_column(record, input_name)
    if record.kind_of? Configure
      id = record.id
      options = [['dropbox','dropbox'],['static_rss','static_rss']]
      select_tag 'record[feed_source]', options_for_select(options, id), :style=>''
    else
      super
    end
  end
  # override active_scaffold/helpers/view_helpers.rb
  def render_action_link(link, record = nil, options = {})
    if !!options[:for]
      record = options[:for] if !record
      link.parameters[:branch] = record.branch if !!record.respond_to?(:branch)
    end
    super
  end

end
