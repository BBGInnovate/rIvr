module BranchesHelper
  
  def forum_options
    [[Branch.forum_type_ui('report'),'report'],
     [Branch.forum_type_ui('bulletin'),'bulletin'],
     [Branch.forum_type_ui('vote'),'vote'],
     [Branch.forum_type_ui('vote_ended'),'vote_ended']]
  end
  def forum_type_form_column(record, input_name)
    id = record.forum_type
    options = forum_options
    select_tag 'record[forum_type]', options_for_select(options, id), :id=>'forum-type' 
  end
  
  def vote_result_column(record, input_name)
    if (record.kind_of? Branch) && record.forum_type=='vote'
      yes="Voted Yes:" + record.vote_results.yes.size.to_s
      no="Voted No:" + record.vote_results.no.size.to_s
      none="Voted None:" + record.vote_results.none.size.to_s
      "<span id='#{record.id}' title='#{yes} <br />#{no} <br />#{none}' class='branch-name-tip'>Hover to View Details</span>".html_safe
    else
      ''
    end
  end 

end