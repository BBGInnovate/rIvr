module BranchesHelper
  
  def forum_options
    [['Report','report'],['Bulletin Board','bulletin'],['Vote/Poll','vote']]
  end
  def forum_type_form_column(record, input_name)
    id = record.forum_type
    options = forum_options
    select_tag 'record[forum_type]', options_for_select(options, id), :id=>'forum-type' 
  end
end