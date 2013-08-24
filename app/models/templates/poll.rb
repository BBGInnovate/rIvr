class Poll < Template
  validates :identifier, :presence => true, :length => {:minimum=>4, :maximum => 40 }
end