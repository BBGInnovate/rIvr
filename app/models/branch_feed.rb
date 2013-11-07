class BranchFeed< ActiveRecord::Base
  belongs_to :branch
  belongs_to :voting_session, :foreign_key=>'forum_session_id'
end