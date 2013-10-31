class VotingSession< ActiveRecord::Base
  belongs_to :branch
  has_many :templates
  has_many :entries, :foreign_key=>'forum_session_id'
  
  before_save :update_friendly_name
  after_save :activate_templates
  
  def update_friendly_name
    self.friendly_name=self.name.parameterize
  end
  
  def activate_templates
    if self.is_active == true
      templates.where("description != 'result'").update_all :is_active=>true
      entries.update_all :is_active=>true
      generate_forum_feed_xml
    end
  end
  
  def activate_result_templates
    if self.is_active == true
      self.branch.votes.result_templates.update_all :is_active=>true
      generate_forum_feed_xml
    end
  end
  
#  def friendly_name
#    fr = read_attribute(:friendly_name)
#    if fr 
#      fr
#    else    
#      name.parameterize
#    end
#  end
  
  def self.find_me(attr)
    self.first :conditions=>["id=? or name=? or friendly_name=?", attr, attr, attr]
  end
  
  protected
  def generate_forum_feed_xml(client=nil)
    if self.is_active && self.branch
      self.branch.generate_forum_feed_xml
    end
  end
end