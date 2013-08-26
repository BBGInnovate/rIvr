class VoteResult < ActiveRecord::Base
  belongs_to :branch
  # after_save :generate_forum_feed
  # self.inheritance_column = "vote_type"
  default_scope where("is_active=1")
end