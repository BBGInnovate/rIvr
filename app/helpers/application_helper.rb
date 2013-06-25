module ApplicationHelper
  def branch_form_column(record, input_name)
    if !record.kind_of?(Branch)
      id = record.branch
      options = Branch.where("is_active=1").map{|b| [b.name, b.name]}
      select_tag 'record[branch]', options_for_select(options, id), :style=>''
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
