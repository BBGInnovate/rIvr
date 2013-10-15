class VotingSession< ActiveRecord::Base
  belongs_to :branch
  
  after_save :generate_forum_feed_xml
  
  def generate_forum_feed_xml(client=nil)
    if self.is_active
      self.branch.generate_forum_feed_xml
    end
  end
end