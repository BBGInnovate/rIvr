module BranchesHelper
  
  def branch_forum(forum_session)
    if forum_session.branch
      "#{forum_session.branch.name} : #{forum_session.name}"
    else
      nil
    end
  end
  
  def forum_options
    re = []
    Branch.forum_types.each do |t|
      re << [Branch.forum_type_ui(t),t]
    end
    re
  end
  
  def forum_titles
    re = [['All Forum','0']]
    VotingSession.includes(:branch).where(:is_active=>true).
      order("created_at desc").each do |t|
       if t.branch && t.branch.is_active
         re << [t.name,t.id]
       end
    end
    re
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