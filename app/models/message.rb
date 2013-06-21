class Message < ActiveRecord::Base
  validates :name, :presence => true, :length => { :maximum => 255 }
  validates :description, :length => { :maximum => 255 }
     
end