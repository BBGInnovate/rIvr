require 'dropbox'
require 'open-uri'
require 'builder'

class Vote < Template
  HUMANIZED_COLUMNS = {:identifier=>"Name"}
    
      def self.human_attribute_name(attribute, options = {})
        HUMANIZED_COLUMNS[attribute.to_sym] ||
        attribute.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
      end
      
  validates :identifier, :presence => true,:length => {:minimum=>6, :maximum=>40}
   
  def identifier
    self.voting_session.name rescue nil
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
    if !votingsession && self.name =='introduction'
      votingsession = VotingSession.create :branch_id=>self.branch_id, :name=>name
    end
    self.voting_session_id=votingsession.id
    self.save!
  end
end