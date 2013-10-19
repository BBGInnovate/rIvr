require 'dropbox'
require 'open-uri'
require 'builder'

class Bulletin < Template
#  belongs_to :voting_session
  def identifier
    # if this template is saved before
    if self.voting_session
      self.voting_session.name
    # if introduction template is saved before
    elsif !!self.branch.bulletins.last && self.branch.bulletins.last.voting_session
      self.branch.bulletins.last.voting_session.name rescue nil
    else
      nil
    end
  end
end