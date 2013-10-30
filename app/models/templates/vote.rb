require 'dropbox'
require 'open-uri'
require 'builder'

class Vote < Template
 # belongs_to :voting_session
  
  HUMANIZED_COLUMNS = {:identifier=>"Vote/Poll Title"}
    
      def self.human_attribute_name(attribute, options = {})
        HUMANIZED_COLUMNS[attribute.to_sym] ||
        attribute.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
      end
      
  validates :identifier, :length => {:minimum=>6, :maximum=>40},
      :if => Proc.new {|c| !!c.identifier}
   
  def identifier
    # if this template is saved before
    if self.voting_session
      self.voting_session.friendly_name
    # if introduction template is saved before
    elsif !!self.branch.votes.last && self.branch.votes.last.voting_session
      self.branch.votes.last.voting_session.friendly_name rescue nil
    else
      nil
    end
  end
  
  def identifier=(name)
    if !name
       self.errors[:base] << "Vote/Poll name cannot be blank"
       return
    elsif name.size < 6 || name.size > 40
       self.errors[:base] << "Vote/Poll name must be within 6 and 40 characters" 
       return 
    end
    votingsession = VotingSession.where(:branch_id=>self.branch_id, :name=>name).last
    # only introduction to create a voting session
    # the other template should use this voting session
    if !votingsession
      votingsession = VotingSession.create :branch_id=>self.branch_id, 
         :name=>name,:is_active=>false
    end
    self.voting_session_id=votingsession.id
    self.save!
  end
  
  def name_map(name)
    {'introduction'=>'Introduction','candidate'=>'Vote/Poll'}[name]
  end
end