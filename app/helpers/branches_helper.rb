module BranchesHelper
  def forum_type_form_column(record, input_name)
    id = record.forum_type
    options = [['--Select--',''], ['Report','report'],['Bulletin Board','bulletin']]
    select_tag 'record[forum_type]', options_for_select(options, id), :id=>'forum-type' 
  end
end