class VotingSession< ActiveRecord::Base
  belongs_to :branch
  has_many :templates
  has_many :entries, :foreign_key=>'forum_session_id'
  
  after_save :activate_templates
  
  def activate_templates
    templates.update_all :is_active=>true
    entries.update_all :is_active=>true
    generate_forum_feed_xml
  end
  
  def friendly_name
    name.parameterize
  end
  
  protected
  def generate_forum_feed_xml(client=nil)
    if self.is_active
      self.branch.generate_forum_feed_xml
    end
  end
end