module OptionsHelper
  def branch_name_form_column(record, input_name)
    if !record.kind_of?(Branch)
    id = record.branch_id rescue 0
      options = Branch.where("is_active=1").map{|b| [b.name, b.id]}
      options.unshift ["Global Option","0"]
      select_tag 'record[branch_id]', options_for_select(options, id), :style=>'width: 200px;'
    else
      super
    end
  end
end